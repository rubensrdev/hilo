import SwiftUI

// contrato 1: dos destinos, Memoria y Preguntar; la hoja de contar envuelve Captura + Revision tal cual
struct RootScreen: View {
  let exploreState: ExploreState
  let captureState: CaptureState
  @Bindable var reviewCoordinator: ReviewCoordinator
  @Binding var isCapturePresented: Bool

  var body: some View {
    TabView {
      Tab("Memory", systemImage: "square.stack") {
        MemoryScreen(state: exploreState, isCapturePresented: $isCapturePresented)
      }
      Tab("Ask", systemImage: "text.magnifyingglass") {
        AskScreen()
      }
    }
    .sheet(
      isPresented: $isCapturePresented,
      onDismiss: { Task { await exploreState.load() } }
    ) {
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
  }
}

#if DEBUG
  #Preview("Root, empty memory") {
    let actor = PreviewFixtures.persistenceActor()
    let coordinator = ReviewCoordinator(persistenceActor: actor)
    let capture = CaptureState(
      comprehender: PreviewComprehender(scenario: .empty),
      persistenceActor: actor, interfaceLanguage: "en"
    ) { _, _, _, _ in }
    return RootScreen(
      exploreState: ExploreState(
        persistenceActor: actor, comprehender: PreviewComprehender(scenario: .empty),
        interfaceLanguage: "en"),
      captureState: capture,
      reviewCoordinator: coordinator, isCapturePresented: .constant(false))
  }
#endif
