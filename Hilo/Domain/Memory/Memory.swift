import Foundation

nonisolated struct MemoryID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

/// Rule 1: a memory without a narrative does not exist, and the narrative is never rewritten.
nonisolated struct Memory: Sendable, Identifiable, Equatable {
  let id: MemoryID
  let narrative: String
  let date: MemoryDate?
  /// System time, never the user's date. Whoever saves sets it; Domain never reads the clock.
  let savedAt: Date

  init?(narrative: String, date: MemoryDate? = nil, savedAt: Date) {
    guard !narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.id = MemoryID()
    self.narrative = narrative
    self.date = date
    self.savedAt = savedAt
  }

  /// Rebuilds from persistence, keeping the id validated at save time.
  init(id: MemoryID, narrative: String, date: MemoryDate? = nil, savedAt: Date) {
    self.id = id
    self.narrative = narrative
    self.date = date
    self.savedAt = savedAt
  }

  /// Rule 17: the deduced year only sorts. Ties break by save time, then by id, so the order is total.
  static func isOrderedBefore(_ a: Memory, _ b: Memory) -> Bool {
    let yearA = a.date?.deducedYear
    let yearB = b.date?.deducedYear

    switch (yearA, yearB) {
    case (.some(let ya), .some(let yb)) where ya != yb:
      return ya > yb
    case (.some, .none):
      return true
    case (.none, .some):
      return false
    default:
      break
    }

    if a.savedAt != b.savedAt {
      return a.savedAt > b.savedAt
    }

    return a.id.value.uuidString < b.id.value.uuidString
  }
}
