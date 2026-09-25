import SwiftUI

struct ElementsView: View {
  @Bindable var state: ExploreState
  @Environment(\.locale) private var environmentLocale
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Spacing.espacio4) {
        filterChips
        if state.filteredElements.isEmpty {
          Text("No matches for this filter")
            .tituloSeccion()
            .foregroundStyle(Color.textoSecundario)
            .accessibilityIdentifier("explore.elementsFilterNoResults")
        } else {
          LazyVStack(spacing: Spacing.espacio1) {
            ForEach(state.filteredElements) { element in
              NavigationLink(value: element.id) {
                ElementRow(element: element, memoryCount: state.memoryCount(for: element))
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Spacing.margenPantalla)
    }
    .background(Color.fondo)
  }

  /// Single selection: tapping the active chip goes back to all. At accessibility sizes, a column, never a scroll.
  @ViewBuilder
  private var filterChips: some View {
    let layout = dynamicTypeSize.rowLayout(spacing: Spacing.separacionChips)
    let chips = layout {
      filterChip(nil, label: ExploreCopy.allFilterLabel(locale: interfaceLocale))
      filterChip(.person, label: ElementType.person.localizedPluralName(locale: interfaceLocale))
      filterChip(.place, label: ElementType.place.localizedPluralName(locale: interfaceLocale))
      filterChip(.object, label: ElementType.object.localizedPluralName(locale: interfaceLocale))
    }
    if dynamicTypeSize.isAccessibilitySize {
      chips
    } else {
      ScrollView(.horizontal, showsIndicators: false) { chips }
    }
  }

  private func filterChip(_ type: ElementType?, label: String) -> some View {
    let isSelected = state.selectedElementTypeFilter == type
    return Button {
      state.selectedElementTypeFilter = isSelected ? nil : type
    } label: {
      Label {
        Text(label).chipElemento()
      } icon: {
        if let type {
          Image(systemName: type.symbolName)
        }
      }
      .padding(.horizontal, Spacing.espacio3)
      .frame(minHeight: Spacing.altoFilaMinimo)
    }
    .foregroundStyle(isSelected ? Color.seleccionado : Color.textoPrimario)
    .background(Color.chipRelleno)
    .clipShape(Spacing.radioChip)
    .overlay {
      if isSelected {
        Spacing.radioChip.strokeBorder(
          Color.bordeChipConocido, lineWidth: Spacing.trazoChipConocido)
      }
    }
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

#if DEBUG
  #Preview("With content", traits: .modifier(ExploreScenarios(.elementsList))) {
    ExplorePreviewScreen()
  }
  #Preview(
    "Filter, no results",
    traits: .modifier(ExploreScenarios(.elementsFilterNoResults))
  ) { ExplorePreviewScreen() }
  #Preview(
    "With content, AX5", traits: .modifier(ExploreScenarios(.elementsList))
  ) { ExplorePreviewScreen().dynamicTypeSize(.accessibility5) }
#endif
