import SwiftUI

// contrato 2 (S1) + contrato 4 (S4): simbolo, color y nombre de un elemento, siempre juntos (P1)
struct ElementChip: View {
  let element: Element
  // F5.5: cuando se conoce, VoiceOver anuncia tambien el tipo y en cuantos recuerdos aparece —
  // el chip visual solo muestra el nombre, asi que sin esto el tipo (color+simbolo) se pierde
  // para quien no ve el color (regla de accesibilidad, no solo P1)
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
