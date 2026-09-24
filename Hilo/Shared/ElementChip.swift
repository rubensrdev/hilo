import SwiftUI

// contrato 2 (S1) + contrato 4 (S4): simbolo, color y nombre de un elemento, siempre juntos (P1)
struct ElementChip: View {
  let element: Element

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
  }
}

#if DEBUG
  #Preview {
    ElementChip(element: PreviewFixtures.exploreElement)
      .padding()
      .background(Color.fondo)
  }
#endif
