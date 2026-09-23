import Foundation
import OSLog

// contrato 5: puente entre Captura y Revision. El closure onUnderstood de CaptureState se
// construye en el init de HiloApp antes de que exista self, asi que no puede tocar un @State
// de la app directamente — captura esta clase (una referencia) en su lugar
@Observable
final class ReviewCoordinator {
  // la misma hoja pasa de la revision al momento de la conexion: el id no cambia, no se re-presenta
  struct Presentation: Identifiable {
    enum Stage {
      case review(ReviewState, narrative: String)
      case connected(ConnectionMoment)
    }

    let id = UUID()
    var stage: Stage
  }

  var presentation: Presentation?
  // DEC-47 + punto 3 de F4.6: si la hoja no llega a abrirse, se vuelve como al cerrarla y se avisa
  var onPreparationFailed: () -> Void = {}

  private let persistenceActor: PersistenceActor
  private let logger = Logger(subsystem: "com.hilo.app", category: "revision")

  init(persistenceActor: PersistenceActor) {
    self.persistenceActor = persistenceActor
  }

  // la foto no hace falta aqui: Revision no la muestra (no es uno de los cuatro bloques),
  // F4.5 la reutiliza tal cual desde la persistencia al guardar de verdad
  func present(extracted: ExtractedMemory, narrative: String, savedMemoryID: MemoryID?) {
    Task {
      do {
        // en paralelo: dos lecturas independientes sobre el mismo actor, sin dependencia entre si
        async let knownElements = persistenceActor.fetchElements()
        async let appearances = persistenceActor.fetchAppearances()
        presentation = try await Presentation(
          stage: .review(
            ReviewState(
              extracted: extracted, knownElements: knownElements, appearances: appearances,
              excludingMemoryID: savedMemoryID),
            narrative: narrative))
      } catch {
        // solo el tipo: el error no debe arrastrar al log nada del usuario
        logger.error(
          "No se pudo preparar la revision: \(String(describing: type(of: error)), privacy: .public)"
        )
        onPreparationFailed()
      }
    }
  }

  // DEC-49: sin conexiones no hay momento, la hoja se cierra y queda la captura vacia
  @discardableResult
  func showConnections(savedMemoryID: MemoryID) -> Task<Void, Never> {
    // deslizada durante el guardado: ni se lee ni se reabre
    guard let sheetID = presentation?.id else { return Task {} }
    return Task {
      let moment: ConnectionMoment?
      do {
        moment = try await persistenceActor.connectionMoment(for: savedMemoryID)
      } catch {
        // el recuerdo ya esta guardado: sin poder leer sus conexiones, se cierra como sin conexiones
        logger.error(
          "No se pudieron leer las conexiones: \(String(describing: type(of: error)), privacy: .public)"
        )
        moment = nil
      }
      // solo la hoja de este guardado: si se cerro o es otra, no se toca
      guard presentation?.id == sheetID else { return }
      if let moment {
        presentation?.stage = .connected(moment)
      } else {
        presentation = nil
      }
    }
  }

  func closeAfterFailedSave() {
    presentation = nil
  }
}
