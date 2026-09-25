/// Derived from appearances, never stored.
nonisolated struct MemoryConnection: Sendable, Equatable {
  let memoryID: MemoryID
  let motives: [ElementID]
}

nonisolated enum MemoryConnections {
  static func connected(to memory: Memory, appearances: [Appearance]) -> [MemoryConnection] {
    // Motives follow the origin memory's own appearance order, never the other memory's.
    let ownOrder = MemoryElements.elementIDs(for: memory.id, in: appearances)
    let ownElements = Set(ownOrder)

    // Connections follow the first qualifying appearance of each other memory.
    var connectionOrder: [MemoryID] = []
    var seenMemories: Set<MemoryID> = []
    var sharedElementsByMemory: [MemoryID: Set<ElementID>] = [:]

    for appearance in appearances {
      guard appearance.memoryID != memory.id, ownElements.contains(appearance.elementID) else {
        continue
      }
      if seenMemories.insert(appearance.memoryID).inserted {
        connectionOrder.append(appearance.memoryID)
      }
      sharedElementsByMemory[appearance.memoryID, default: []].insert(appearance.elementID)
    }

    return connectionOrder.map { connectedID in
      let shared = sharedElementsByMemory[connectedID] ?? []
      return MemoryConnection(memoryID: connectedID, motives: ownOrder.filter(shared.contains))
    }
  }
}
