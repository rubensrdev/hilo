import Foundation

nonisolated struct MemorySearchResult: Sendable, Equatable {
  let memoryID: MemoryID
  let narrativeMatches: [Range<String.Index>]
  let extract: Range<String.Index>?
  let matchedElementIDs: [ElementID]
}

// contrato 3, DEC-15 + DEC-20 + DEC-57: relato y elementos vinculados, extracto centrado, sin tope
nonisolated enum MemorySearch {
  static func results(
    for query: String, in memories: [Memory], elements: [Element],
    appearances: [Appearance], defaultExtractLength: Int
  ) -> [MemorySearchResult] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    var results: [MemorySearchResult] = []
    for memory in memories.sorted(by: Memory.isOrderedBefore) {
      let narrativeMatches = narrativeMatches(of: trimmed, in: memory.narrative)
      let matchedElementIDs = matchingElementIDs(
        for: trimmed, memoryID: memory.id, elements: elements, appearances: appearances)
      guard !narrativeMatches.isEmpty || !matchedElementIDs.isEmpty else { continue }

      let extract =
        narrativeMatches.isEmpty
        ? nil
        : extractRange(
          in: memory.narrative, matches: narrativeMatches,
          defaultExtractLength: defaultExtractLength)
      results.append(
        MemorySearchResult(
          memoryID: memory.id, narrativeMatches: narrativeMatches, extract: extract,
          matchedElementIDs: matchedElementIDs))
    }
    return results
  }

  static func narrativeMatches(of query: String, in narrative: String) -> [Range<String.Index>] {
    guard !query.isEmpty else { return [] }
    var ranges: [Range<String.Index>] = []
    var searchStart = narrative.startIndex
    while let found = narrative.range(
      of: query, options: [.caseInsensitive, .diacriticInsensitive],
      range: searchStart..<narrative.endIndex)
    {
      ranges.append(found)
      searchStart = found.upperBound
    }
    return ranges
  }

  // DEC-20: dentro si el inicio de la coincidencia cabe en el recorte por defecto; si no, se centra
  static func extractRange(
    in narrative: String, matches: [Range<String.Index>], defaultExtractLength: Int
  ) -> Range<String.Index> {
    let defaultEnd =
      narrative.index(
        narrative.startIndex, offsetBy: defaultExtractLength, limitedBy: narrative.endIndex)
      ?? narrative.endIndex
    guard let firstMatch = matches.first, firstMatch.lowerBound >= defaultEnd else {
      return narrative.startIndex..<defaultEnd
    }

    let matchMidOffset =
      narrative.distance(from: narrative.startIndex, to: firstMatch.lowerBound)
      + narrative.distance(from: firstMatch.lowerBound, to: firstMatch.upperBound) / 2
    let desiredStartOffset = max(0, matchMidOffset - defaultExtractLength / 2)
    // nunca encoge la ventana por debajo del presupuesto si el relato da para mas: desliza hacia atras
    let maxStartOffset = max(0, narrative.count - defaultExtractLength)
    let startOffset = min(desiredStartOffset, maxStartOffset)

    let start = narrative.index(narrative.startIndex, offsetBy: startOffset)
    let end =
      narrative.index(start, offsetBy: defaultExtractLength, limitedBy: narrative.endIndex)
      ?? narrative.endIndex
    return start..<end
  }

  static func matchingElementIDs(
    for query: String, memoryID: MemoryID, elements: [Element], appearances: [Appearance]
  ) -> [ElementID] {
    guard !query.isEmpty else { return [] }
    let elementsByID = Dictionary(uniqueKeysWithValues: elements.map { ($0.id, $0) })

    var order: [ElementID] = []
    var seen: Set<ElementID> = []
    for appearance in appearances where appearance.memoryID == memoryID {
      guard seen.insert(appearance.elementID).inserted else { continue }
      guard let element = elementsByID[appearance.elementID] else { continue }
      guard
        matches(query: query, in: element.displayName)
          || element.aliases.contains(where: { matches(query: query, in: $0) })
      else { continue }
      order.append(element.id)
    }
    return order
  }

  // busqueda por substring, sin el recorte de articulo inicial de CanonicalName: no es identidad
  private static func matches(query: String, in name: String) -> Bool {
    folded(name).contains(folded(query))
  }

  private static func folded(_ text: String) -> String {
    text.folding(
      options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
  }
}
