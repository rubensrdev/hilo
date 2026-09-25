import Foundation

/// The memory just saved and its connections, each with its motive.
nonisolated struct ConnectionMoment: Sendable, Equatable {
  nonisolated struct Row: Sendable, Equatable {
    let memoryID: MemoryID
    let narrative: String
    let motiveNames: [String]
  }

  let narrative: String
  let dateText: String?
  let rows: [Row]

  /// No connections, no moment.
  init?(savedMemoryID: MemoryID, memories: [Memory], elements: [Element], appearances: [Appearance]) {
    guard let saved = memories.first(where: { $0.id == savedMemoryID }) else { return nil }
    let narratives = Dictionary(
      memories.map { ($0.id, $0.narrative) }, uniquingKeysWith: { first, _ in first })
    let elementsByID = Dictionary(
      elements.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    // A connection without a nameable motive is never shown.
    let rows = MemoryConnections.connected(to: saved, appearances: appearances).compactMap {
      connection -> (row: Row, firstType: ElementType)? in
      let motives = connection.motives.compactMap { elementsByID[$0] }.stablySortedByType(\.type)
      guard let narrative = narratives[connection.memoryID], let first = motives.first else {
        return nil
      }
      let row = Row(
        memoryID: connection.memoryID, narrative: narrative, motiveNames: motives.map(\.displayName))
      return (row, first.type)
    }
    .stablySortedByType(\.firstType)
    .map(\.row)
    guard !rows.isEmpty else { return nil }
    self.narrative = saved.narrative
    self.dateText = saved.date?.text
    self.rows = rows
  }
}

extension Array {
  /// Same order as the review's understood block, stable within each type.
  nonisolated fileprivate func stablySortedByType(_ elementType: (Element) -> ElementType)
    -> [Element]
  {
    let order = ElementType.reviewOrder
    return enumerated()
      .sorted { lhs, rhs in
        let lhsRank = order.firstIndex(of: elementType(lhs.element)) ?? order.count
        let rhsRank = order.firstIndex(of: elementType(rhs.element)) ?? order.count
        return (lhsRank, lhs.offset) < (rhsRank, rhs.offset)
      }
      .map(\.element)
  }
}
