import SwiftUI

// contrato 4: simbolo, color y texto del tipo siempre juntos (P1); nombre y numero de recuerdos
struct ElementRow: View {
  let element: Element
  let memoryCount: Int
  @Environment(\.locale) private var environmentLocale

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  var body: some View {
    HStack(spacing: Spacing.espacio3) {
      Image(systemName: element.type.symbolName)
        .foregroundStyle(element.type.color)
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Text(element.displayName)
          .nombreElemento()
          .foregroundStyle(Color.textoPrimario)
        Text(element.type.localizedName(locale: interfaceLocale))
          .metadato()
          .foregroundStyle(Color.textoSecundario)
      }
      Spacer()
      Text(ExploreCopy.elementMemoryCount(memoryCount, locale: interfaceLocale))
        .metadato()
        .foregroundStyle(Color.textoSecundario)
    }
    .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
    // sin fondo propio (a diferencia de MemoryCard/ElementChip), asi que el Spacer central
    // queda transparente al toque sin esto: el NavigationLink que la envuelve fallaba en
    // silencio si se tocaba ahi (hallado por verificador-ui)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
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
