import SwiftUI

struct ElementChip: View {
  let element: Element
  /// The chip only shows the name; VoiceOver needs the type and the count as text.
  var memoryCount: Int? = nil
  @Environment(\.locale) private var environmentLocale

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  var body: some View {
    Label {
      Text(element.displayName)
        .chipElemento()
        .foregroundStyle(Color.textoPrimario)
    } icon: {
      Image(systemName: element.type.symbolName)
        .foregroundStyle(element.type.color)
    }
    .padding(.horizontal, Spacing.espacio3)
    .padding(.vertical, Spacing.espacio1)
    .background(Color.chipRelleno)
    .clipShape(Spacing.radioChip)
    // Outside the review the chip is "new"; the colorset only paints in high contrast.
    .overlay {
      Spacing.radioChip.strokeBorder(Color.bordeChipNuevo, lineWidth: Spacing.trazoBordeTarjeta)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      element.accessibilityLabel(memoryCount: memoryCount, locale: interfaceLocale))
  }
}

#if DEBUG
  #Preview {
    ElementChip(element: PreviewFixtures.exploreElement, memoryCount: 4)
      .padding()
      .background(Color.fondo)
  }
#endif
