import SwiftUI

// contrato 2 + contrato 3: primeras lineas del relato, fecha del usuario si la hay, sin titulo, sin foto aun
// (la foto vive en PersistenceActor, no en Memory — esta tarea no la trae a S1, la retoma F5.3 en S4)
struct MemoryCard: View {
  let memory: Memory
  // contrato 3, DEC-20: cuando hay una busqueda activa, la tarjeta se centra en la coincidencia
  var searchMatches: [Range<String.Index>] = []
  var searchExtract: Range<String.Index>?
  // contrato 3 + DEC-57: si el recuerdo aparece por elemento y no por el relato, se enseñan todos, sin tope
  // F5.5: el recuento acompaña a cada elemento para que VoiceOver anuncie nombre, tipo y recuento
  var matchedElements: [(element: Element, memoryCount: Int)] = []

  private var displayedRange: Range<String.Index> {
    searchExtract ?? memory.narrative.startIndex..<memory.narrative.endIndex
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      narrativeText
        .relatoExtracto()
        .foregroundStyle(Color.textoPrimario)
        .lineLimit(searchExtract == nil ? 4 : nil)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let dateText = memory.date?.text {
        Text(dateText)
          .fechaUsuario()
          .foregroundStyle(Color.textoSecundario)
      }
      if !matchedElements.isEmpty {
        // vertical siempre: sin tope de elementos (DEC-57), no hay ancho seguro para envolver en linea
        VStack(alignment: .leading, spacing: Spacing.espacio1) {
          ForEach(matchedElements, id: \.element.id) { match in
            ElementChip(element: match.element, memoryCount: match.memoryCount)
          }
        }
      }
    }
    .padding(Spacing.rellenoTarjeta)
    .background(Color.superficieTarjeta)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  // tokens.md §1.7: el termino encontrado va en semibold, sin color ni fondo
  // Text + Text esta obsoleto desde iOS 26: se compone un AttributedString y se envuelve una vez
  private var narrativeText: Text {
    guard !searchMatches.isEmpty else { return Text(memory.narrative[displayedRange]) }
    var result = AttributedString()
    var cursor = displayedRange.lowerBound
    for match in searchMatches {
      let clamped = match.clamped(to: displayedRange)
      guard clamped.lowerBound < clamped.upperBound, clamped.lowerBound >= cursor else { continue }
      if cursor < clamped.lowerBound {
        result += AttributedString(memory.narrative[cursor..<clamped.lowerBound])
      }
      var matched = AttributedString(memory.narrative[clamped])
      // el peso cambia, la familia serif del relato se mantiene igual (tokens.md §2.1)
      matched.font = Font.system(.body, design: .serif).weight(.semibold)
      result += matched
      cursor = clamped.upperBound
    }
    if cursor < displayedRange.upperBound {
      result += AttributedString(memory.narrative[cursor..<displayedRange.upperBound])
    }
    return Text(result)
  }
}

#if DEBUG
  #Preview("No photo, with date") {
    MemoryCard(memory: PreviewFixtures.exploreMemory)
      .padding()
      .background(Color.fondo)
  }
  #Preview("Search match, centered extract") {
    let memory = PreviewFixtures.exploreMemory
    let query = "Singer"
    let matches = MemorySearch.narrativeMatches(of: query, in: memory.narrative)
    let extract = MemorySearch.extractRange(
      in: memory.narrative, matches: matches, defaultExtractLength: 60)
    return MemoryCard(memory: memory, searchMatches: matches, searchExtract: extract)
      .padding()
      .background(Color.fondo)
  }
  #Preview("Matched by element, not narrative") {
    MemoryCard(
      memory: PreviewFixtures.exploreMemory,
      matchedElements: [
        (PreviewFixtures.exploreElement, 4), (Element(displayName: "Cádiz", type: .place)!, 1),
      ]
    )
    .padding()
    .background(Color.fondo)
  }
  #Preview("AX5") {
    MemoryCard(memory: PreviewFixtures.exploreMemory)
      .padding()
      .background(Color.fondo)
      .dynamicTypeSize(.accessibility5)
  }
#endif
