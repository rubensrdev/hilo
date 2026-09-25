import SwiftUI

/// No title and no photo: the photo lives in PersistenceActor, not in Memory.
struct MemoryCard: View {
  let memory: Memory
  /// With an active search, the card centres on the match.
  var searchMatches: [Range<String.Index>] = []
  var searchExtract: Range<String.Index>?
  /// When the memory matches by element rather than by narrative, every match is shown, uncapped,
  /// each with its count so VoiceOver can announce it.
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
        // Always vertical: with no cap on elements there is no safe width to wrap inline.
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
    .contornoTarjeta()
    .accessibilityElement(children: .combine)
  }

  /// The match goes semibold, with no colour or background. Text + Text is deprecated since iOS 26,
  /// so one AttributedString is composed and wrapped once.
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
      // Only the weight changes; the narrative keeps its serif family.
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
        (PreviewFixtures.exploreElement, 4), (PreviewFixtures.explorePlace, 1),
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
