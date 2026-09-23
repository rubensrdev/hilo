import Foundation

// contrato 5: el recuerdo recien guardado y sus conexiones, cada una con su motivo
nonisolated struct ConnectionMoment: Sendable, Equatable {
  nonisolated struct Row: Sendable, Equatable {
    let memoryID: MemoryID
    let narrative: String
    let motiveNames: [String]
  }

  let narrative: String
  let dateText: String?
  let rows: [Row]

  // DEC-49: sin conexiones no hay momento
  init?(savedMemoryID: MemoryID, memories: [Memory], elements: [Element], appearances: [Appearance]) {
    guard let saved = memories.first(where: { $0.id == savedMemoryID }) else { return nil }
    let narratives = Dictionary(
      memories.map { ($0.id, $0.narrative) }, uniquingKeysWith: { first, _ in first })
    let names = Dictionary(
      elements.map { ($0.id, $0.displayName) }, uniquingKeysWith: { first, _ in first })
    // una conexion sin motivo nombrable no se ensena (regla 4 del diseño)
    let rows = MemoryConnections.connected(to: saved, appearances: appearances).compactMap {
      connection -> Row? in
      let motiveNames = connection.motives.compactMap { names[$0] }
      guard let narrative = narratives[connection.memoryID], !motiveNames.isEmpty else {
        return nil
      }
      return Row(memoryID: connection.memoryID, narrative: narrative, motiveNames: motiveNames)
    }
    guard !rows.isEmpty else { return nil }
    self.narrative = saved.narrative
    self.dateText = saved.date?.text
    self.rows = rows
  }
}
