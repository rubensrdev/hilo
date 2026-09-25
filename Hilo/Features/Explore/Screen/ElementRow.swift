import SwiftUI

struct ElementRow: View {
  let element: Element
  let memoryCount: Int
  @Environment(\.locale) private var environmentLocale
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  private var countText: some View {
    Text(ExploreCopy.elementMemoryCount(memoryCount, locale: interfaceLocale))
      .metadato()
      .foregroundStyle(Color.textoSecundario)
  }

  var body: some View {
    HStack(alignment: .top, spacing: Spacing.espacio3) {
      // Hidden, or VoiceOver announces the SF Symbol on top of the type's text.
      Image(systemName: element.type.symbolName)
        .foregroundStyle(element.type.color)
        .accessibilityHidden(true)
      // At accessibility sizes the count drops below the type instead of sharing its line.
      let layout = dynamicTypeSize.rowLayout(alignment: .top, spacing: Spacing.espacio1)
      layout {
        VStack(alignment: .leading, spacing: Spacing.espacio1) {
          Text(element.displayName)
            .nombreElemento()
            .foregroundStyle(Color.textoPrimario)
          Text(element.type.localizedName(locale: interfaceLocale))
            .metadato()
            .foregroundStyle(Color.textoSecundario)
        }
        if !dynamicTypeSize.isAccessibilitySize {
          Spacer()
        }
        countText
      }
    }
    .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
    // Without its own shape, the central Spacer ignored taps and the NavigationLink missed them.
    .contentShape(Rectangle())
    // The announcement comes from the tested pure function, not from the visible texts.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      element.accessibilityLabel(memoryCount: memoryCount, locale: interfaceLocale))
  }
}

#if DEBUG
  #Preview("Person, several memories") {
    ElementRow(element: PreviewFixtures.exploreElement, memoryCount: 4)
      .padding()
      .background(Color.fondo)
  }
  #Preview("Place, one memory") {
    ElementRow(element: PreviewFixtures.explorePlace, memoryCount: 1)
      .padding()
      .background(Color.fondo)
  }
  #Preview("AX5") {
    ElementRow(element: PreviewFixtures.exploreElement, memoryCount: 4)
      .padding()
      .background(Color.fondo)
      .dynamicTypeSize(.accessibility5)
  }
#endif
