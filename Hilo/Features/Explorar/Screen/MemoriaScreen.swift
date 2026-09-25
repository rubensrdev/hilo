import SwiftUI

// contrato 1: selector superior Recuerdos <-> Elementos (dos vistas del mismo material),
// contar un recuerdo y Ajustes en la barra de herramientas, en todos los tamaños de texto (DEC-12)
struct MemoriaScreen: View {
  @Bindable var state: ExploreState
  @Binding var isCapturePresented: Bool
  // creado al tocar el engranaje: en el closure de la hoja se reevaluaria con cada cambio de ExploreState
  @State private var ajustesState: AjustesState?
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // F8.5 D4: en la barra truncaba a tamaño por defecto (tokens §2.2); a ancho completo como en 02a
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
        // .primaryAction/.secondaryAction pueden colapsar en el menu de desbordamiento del
        // sistema segun el espacio disponible; DEC-12 y DEC-59 piden los dos siempre alcanzables,
        // nunca detras de un "...", asi que van en topBarTrailing (posicional, nunca colapsa)
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            ajustesState = state.makeAjustesState()
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
      .navigationDestination(for: ElementID.self) { elementID in
        ElementDetailScreen(state: state.makeElementDetailState(for: elementID))
      }
    }
    .task { await state.load() }
    .sheet(item: $ajustesState) { AjustesScreen(state: $0) }
  }

  // «People, places & objects» no cabe en un segmento a tamaños AX: .menu enseña el texto entero (F5.5)
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
  // F5.5: el selector superior cambia a .menu en AX para que "People, places & objects" no trunque
  #Preview("AX5", traits: .modifier(ExploreScenarios(.normal))) {
    ExplorePreviewScreen().dynamicTypeSize(.accessibility5)
  }
#endif
