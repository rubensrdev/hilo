import SwiftUI

// contrato 4: simbolo, color y texto del tipo siempre juntos (P1); nombre y numero de recuerdos
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
      // F5.5: sin ocultar, VoiceOver anunciaba el simbolo SF (p.ej. "Person") ademas del
      // texto del tipo justo debajo: doble anuncio del mismo dato
      Image(systemName: element.type.symbolName)
        .foregroundStyle(element.type.color)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Text(element.displayName)
          .nombreElemento()
          .foregroundStyle(Color.textoPrimario)
        Text(element.type.localizedName(locale: interfaceLocale))
          .metadato()
          .foregroundStyle(Color.textoSecundario)
        // P2 (F8.4): en tamaños AX el recuento baja bajo el tipo en vez de compartir la linea
        if dynamicTypeSize.isAccessibilitySize {
          countText
        }
      }
      if !dynamicTypeSize.isAccessibilitySize {
        Spacer()
        countText
      }
    }
    .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
    // sin fondo propio (a diferencia de MemoryCard/ElementChip), asi que el Spacer central
    // queda transparente al toque sin esto: el NavigationLink que la envuelve fallaba en
    // silencio si se tocaba ahi (hallado por verificador-ui)
    .contentShape(Rectangle())
    // F8.4: el anuncio sale de la funcion pura probada, no de los textos visibles
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
    ElementRow(element: Element(displayName: "Cádiz", type: .place)!, memoryCount: 1)
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
