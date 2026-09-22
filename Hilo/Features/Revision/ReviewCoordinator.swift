import Foundation
import OSLog

// contrato 5: puente entre Captura y Revision. El closure onUnderstood de CaptureState se
// construye en el init de HiloApp antes de que exista self, asi que no puede tocar un @State
// de la app directamente — captura esta clase (una referencia) en su lugar
@Observable
final class ReviewCoordinator {
  struct Presentation: Identifiable {
    let id = UUID()
    let reviewState: ReviewState
    let narrative: String
  }

  var presentation: Presentation?

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
          reviewState: ReviewState(
            extracted: extracted, knownElements: knownElements, appearances: appearances,
            excludingMemoryID: savedMemoryID),
          narrative: narrative)
      } catch {
        logger.error("No se pudo preparar la revision: \(error)")
      }
    }
  }
}
