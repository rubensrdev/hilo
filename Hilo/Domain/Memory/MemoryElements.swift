// contrato 4 (S4): los elementos propios de un recuerdo, en orden de primera aparicion
// mismo deduplicado que ElementMemories, en la direccion inversa (recuerdo -> elementos)
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
