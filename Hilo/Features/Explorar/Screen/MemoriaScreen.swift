import SwiftUI

// contrato 1: selector superior Recuerdos <-> Elementos (dos vistas del mismo material),
// contar un recuerdo y Ajustes en la barra de herramientas, en todos los tamaños de texto (DEC-12)
struct MemoriaScreen: View {
  @Bindable var state: ExploreState
  @Binding var isCapturePresented: Bool
  @State private var isAjustesPresented = false

  var body: some View {
    NavigationStack {
      Group {
        switch state.selectedView {
        case .memories:
          MemoriesView(state: state, openCapture: { isCapturePresented = true })
            .searchable(text: $state.searchQuery, prompt: Text("Search your memories"))
        case .elements:
          ElementsView(state: state)
        }
      }
      .navigationTitle("Memory")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Picker("View", selection: $state.selectedView) {
            Text("Memories").tag(ExploreState.SelectedView.memories)
            Text("People, places & objects").tag(ExploreState.SelectedView.elements)
          }
          .pickerStyle(.segmented)
          .tint(Color.acentoHilo)
        }
        // .primaryAction/.secondaryAction pueden colapsar en el menu de desbordamiento del
        // sistema segun el espacio disponible; DEC-12 y DEC-59 piden los dos siempre alcanzables,
        // nunca detras de un "...", asi que van en topBarTrailing (posicional, nunca colapsa)
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isAjustesPresented = true
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
      // fuera del LazyVStack de MemoriesView a proposito: Apple pide no colgar
      // navigationDestination de un contenedor "lazy" para que la pila siempre lo vea
      .navigationDestination(for: MemoryID.self) { memoryID in
        let detailState = state.makeDetailState(for: memoryID)
        MemoryDetailScreen(state: detailState, reviewCoordinator: detailState.reviewCoordinator)
      }
    }
    .task { await state.load() }
    // DEC-59: el acceso existe y es tocable, abre un estado minimo — su contenido real es de F8
    .sheet(isPresented: $isAjustesPresented) { AjustesScreen() }
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
#endif
