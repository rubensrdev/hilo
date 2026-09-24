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
  @State private var exploreState: ExploreState
  // contrato 1, DEC-12: contar un recuerdo se abre desde el toolbar de Memoria, ya no es la raiz
  @State private var isCapturePresented = false

  // el closure de onUnderstood se construye aqui, antes de que self exista, asi que no
  // puede tocar un @State de la app: captura reviewCoordinator (una referencia), no self
  init() {
    let persistenceActor = PersistenceActor(modelContainer: Self.container)
    let comprehender = FoundationModelsMemoryComprehender()
    let interfaceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    let coordinator = ReviewCoordinator(persistenceActor: persistenceActor)
    let capture = CaptureState(
      comprehender: comprehender,
      persistenceActor: persistenceActor,
      interfaceLanguage: interfaceLanguage
    ) { extracted, narrative, _, savedMemoryID in
      coordinator.present(
        extracted: extracted, narrative: narrative, savedMemoryID: savedMemoryID)
    }
    coordinator.onPreparationFailed = { capture.reviewPreparationFailed() }
    capture.onReviewSaved = { coordinator.showConnections(savedMemoryID: $0) }
    capture.onReviewSaveFailed = { coordinator.closeAfterFailedSave() }
    _reviewCoordinator = State(initialValue: coordinator)
    _captureState = State(initialValue: capture)
    _exploreState = State(
      initialValue: ExploreState(
        persistenceActor: persistenceActor, comprehender: comprehender,
        interfaceLanguage: interfaceLanguage))
  }

  var body: some Scene {
    WindowGroup {
      RootScreen(
        exploreState: exploreState, captureState: captureState,
        reviewCoordinator: reviewCoordinator, isCapturePresented: $isCapturePresented)
    }
    .modelContainer(Self.container)
  }
}
