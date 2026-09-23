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

  @State private var captureState: CaptureState
  @State private var reviewCoordinator: ReviewCoordinator

  // el closure de onUnderstood se construye aqui, antes de que self exista, asi que no
  // puede tocar un @State de la app: captura reviewCoordinator (una referencia), no self
  init() {
    let persistenceActor = PersistenceActor(modelContainer: Self.container)
    let coordinator = ReviewCoordinator(persistenceActor: persistenceActor)
    let capture = CaptureState(
      comprehender: FoundationModelsMemoryComprehender(),
      persistenceActor: persistenceActor,
      interfaceLanguage: Locale.current.language.languageCode?.identifier ?? "en"
    ) { extracted, narrative, _, savedMemoryID in
      coordinator.present(
        extracted: extracted, narrative: narrative, savedMemoryID: savedMemoryID)
    }
    coordinator.onPreparationFailed = { capture.reviewDismissed() }
    capture.onReviewSaved = { coordinator.showConnections(savedMemoryID: $0) }
    capture.onReviewSaveFailed = { coordinator.closeAfterFailedSave() }
    _reviewCoordinator = State(initialValue: coordinator)
    _captureState = State(initialValue: capture)
  }

  var body: some Scene {
    WindowGroup {
      CaptureScreen(state: captureState)
        // DEC-47: deslizar y Cancel pasan los dos por aqui; guardar ya ha salido de .reviewing y esto queda inocuo
        .sheet(item: $reviewCoordinator.presentation, onDismiss: captureState.reviewDismissed) {
          presentation in
          switch presentation.stage {
          case .review(let reviewState, let narrative):
            ReviewScreen(initial: reviewState, narrative: narrative) { reviewState, dateText in
              captureState.reviewConfirmed(reviewState, dateTextAtSave: dateText)
            }
          case .connected(let moment):
            ConnectionMomentScreen(moment: moment)
          }
        }
    }
    .modelContainer(Self.container)
  }
}
