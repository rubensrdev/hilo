import SwiftUI

struct MemoryScreen: View {
  @Bindable var state: ExploreState
  @Binding var isCapturePresented: Bool
  /// Created on the gear tap: inside the sheet's closure it would be re-evaluated on every ExploreState change.
  @State private var settingsState: SettingsState?
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // In the bar it truncated at the default text size; full width instead.
        viewPicker
          .padding(.horizontal, Spacing.margenPantalla)
          .padding(.vertical, Spacing.espacio2)
        switch state.selectedView {
        case .memories:
          MemoriesView(state: state, openCapture: { isCapturePresented = true })
            .searchable(text: $state.searchQuery, prompt: Text("Search your memories"))
        case .elements:
          ElementsView(state: state)
        }
      }
      .background(Color.fondo)
      .navigationTitle("Memory")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        // .primaryAction and .secondaryAction can collapse into the overflow menu; both must always be
        // reachable, so they go in .topBarTrailing, which is positional and never collapses.
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            settingsState = state.makeSettingsState()
          } label: {
            Image(systemName: "gearshape")
          }
          .accessibilityLabel("Settings")
          .accessibilityIdentifier("explore.openSettings")
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isCapturePresented = true
          } label: {
            Image(systemName: "square.and.pencil")
          }
          .tint(Color.acentoHilo)
          .accessibilityLabel("Tell a memory")
          .accessibilityIdentifier("explore.openCapture")
        }
      }
      // Outside MemoriesView's LazyVStack on purpose: Apple advises against hanging
      // navigationDestination off a lazy container.
      .navigationDestination(for: MemoryID.self) { memoryID in
        let detailState = state.makeDetailState(for: memoryID)
        MemoryDetailScreen(state: detailState, reviewCoordinator: detailState.reviewCoordinator)
      }
      .navigationDestination(for: ElementID.self) { elementID in
        ElementDetailScreen(state: state.makeElementDetailState(for: elementID))
      }
    }
    .task { await state.load() }
    .sheet(item: $settingsState) { SettingsScreen(state: $0) }
  }

  /// "People, places & objects" doesn't fit a segment at accessibility sizes: .menu shows the whole text.
  @ViewBuilder
  private var viewPicker: some View {
    let picker = Picker("View", selection: $state.selectedView) {
      Text("Memories").tag(ExploreState.SelectedView.memories)
      Text("People, places & objects").tag(ExploreState.SelectedView.elements)
    }
    .tint(Color.acentoHilo)
    .frame(minHeight: Spacing.objetivoToqueMinimo)
    if dynamicTypeSize.isAccessibilitySize {
      picker.pickerStyle(.menu)
    } else {
      picker.pickerStyle(.segmented)
    }
  }
}

#if DEBUG
  #Preview("Normal", traits: .modifier(ExploreScenarios(.normal))) {
    ExplorePreviewScreen()
  }
  #Preview(
    "Elements", traits: .modifier(ExploreScenarios(.elementsList))
  ) { ExplorePreviewScreen() }
  #Preview("Dark", traits: .modifier(ExploreScenarios(.normal))) {
    ExplorePreviewScreen().preferredColorScheme(.dark)
  }
  #Preview("AX5", traits: .modifier(ExploreScenarios(.normal))) {
    ExplorePreviewScreen().dynamicTypeSize(.accessibility5)
  }
#endif
