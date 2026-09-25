/// Distinct memories per element: two appearances in one memory count once, as in MemorySearch.
nonisolated enum ElementMemories {
  static func memoryIDs(for elementID: ElementID, in appearances: [Appearance]) -> [MemoryID] {
    var order: [MemoryID] = []
    var seen: Set<MemoryID> = []
    for appearance in appearances where appearance.elementID == elementID {
      guard seen.insert(appearance.memoryID).inserted else { continue }
      order.append(appearance.memoryID)
    }
    return order
  }

  static func count(for elementID: ElementID, in appearances: [Appearance]) -> Int {
    memoryIDs(for: elementID, in: appearances).count
  }
}
