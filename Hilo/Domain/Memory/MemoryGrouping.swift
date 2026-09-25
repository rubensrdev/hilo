/// Decade of the deduced year; memories without a year stay apart, never merged.
nonisolated enum MemoryDecade: Sendable, Hashable {
  case decade(startingYear: Int)
  case noYear
}

nonisolated struct MemoryGroup: Sendable, Equatable {
  let decade: MemoryDecade
  let memories: [Memory]
}

nonisolated enum MemoryGrouping {
  /// The order already comes from Memory.isOrderedBefore; grouping only detects decade changes.
  static func grouped(_ memories: [Memory]) -> [MemoryGroup] {
    var groups: [MemoryGroup] = []
    for memory in memories.sorted(by: Memory.isOrderedBefore) {
      let decade = decade(of: memory)
      if let last = groups.last, last.decade == decade {
        groups[groups.count - 1] = MemoryGroup(decade: decade, memories: last.memories + [memory])
      } else {
        groups.append(MemoryGroup(decade: decade, memories: [memory]))
      }
    }
    return groups
  }

  private static func decade(of memory: Memory) -> MemoryDecade {
    guard let year = memory.date?.deducedYear else { return .noYear }
    return .decade(startingYear: year - year % 10)
  }
}
