/// A memory's own elements in first-appearance order: ElementMemories in the other direction.
nonisolated enum MemoryElements {
  static func elementIDs(for memoryID: MemoryID, in appearances: [Appearance]) -> [ElementID] {
    var order: [ElementID] = []
    var seen: Set<ElementID> = []
    for appearance in appearances where appearance.memoryID == memoryID {
      guard seen.insert(appearance.elementID).inserted else { continue }
      order.append(appearance.elementID)
    }
    return order
  }
}
