// contrato 4 (lista de elementos) + S5 (F5.4): cuantos recuerdos distintos tiene un elemento
// mismo deduplicado que MemorySearch.matchingElementIDs: dos apariciones en un mismo recuerdo cuentan una vez
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
