import SwiftData
import SwiftUI

@main
struct HiloApp: App {
  /// No initial load: the container is created once and injected, nothing more.
  static let container: ModelContainer = {
    do {
      return try PersistenceContainer.make(inMemory: false)
    } catch {
      fatalError("Could not create the ModelContainer: \(error)")
    }
  }()

  @State private var captureState: CaptureState
  @State private var reviewCoordinator: ReviewCoordinator
  @State private var exploreState: ExploreState
  /// Capture opens from the Memory toolbar; it is not the root.
  @State private var isCapturePresented = false

  /// onUnderstood is built here, before self exists, so it can't touch an app @State: it captures
  /// reviewCoordinator, a reference, instead of self.
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
