import OSLog
import SwiftData
import SwiftUI

@main
struct HiloApp: App {
  // sin carga inicial (contrato 2 de F2): el contenedor se crea una vez y se inyecta, nada más
  static let container: ModelContainer = {
    do {
      return try PersistenceContainer.make(inMemory: false)
    } catch {
      fatalError("No se pudo crear el ModelContainer: \(error)")
    }
  }()

  private static let logger = Logger(subsystem: "com.hilo.app", category: "captura")

  @State private var captureState: CaptureState
  @State private var reviewCoordinator: ReviewCoordinator

  // el closure de onUnderstood se construye aqui, antes de que self exista, asi que no
  // puede tocar un @State de la app: captura reviewCoordinator (una referencia), no self
  init() {
    let persistenceActor = PersistenceActor(modelContainer: Self.container)
    let coordinator = ReviewCoordinator(persistenceActor: persistenceActor)
    _reviewCoordinator = State(initialValue: coordinator)
    _captureState = State(
      initialValue: CaptureState(
        comprehender: FoundationModelsMemoryComprehender(),
        persistenceActor: persistenceActor,
        interfaceLanguage: Locale.current.language.languageCode?.identifier ?? "en"
      ) { extracted, narrative, _, savedMemoryID in
        coordinator.present(
          extracted: extracted, narrative: narrative, savedMemoryID: savedMemoryID)
      })
  }

  var body: some Scene {
    WindowGroup {
      CaptureScreen(state: captureState)
        .sheet(item: $reviewCoordinator.presentation) { presentation in
          ReviewScreen(initial: presentation.reviewState, narrative: presentation.narrative) {
            _, _ in
            // F4.5 sustituye este registro por el guardado real y el momento de la conexion
            Self.logger.notice("Revision saved")
          }
        }
    }
    .modelContainer(Self.container)
  }
}
