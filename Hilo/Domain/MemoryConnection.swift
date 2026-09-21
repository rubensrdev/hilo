// contrato 4: conexion deducida — no se almacena, se calcula a partir de las apariciones (§12)
nonisolated struct MemoryConnection: Sendable, Equatable {
  let memoryID: MemoryID
  let motives: [ElementID]
}

nonisolated enum MemoryConnections {
  static func connected(to memory: Memory, appearances: [Appearance]) -> [MemoryConnection] {
    // orden de motivos: el de las apariciones propias del recuerdo de origen, nunca el del ajeno
    var ownOrder: [ElementID] = []
    var ownElements: Set<ElementID> = []
    for appearance in appearances where appearance.memoryID == memory.id {
      if ownElements.insert(appearance.elementID).inserted {
        ownOrder.append(appearance.elementID)
      }
    }

    // orden de conexiones: por la primera aparicion cualificada de cada memoryID ajeno
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
