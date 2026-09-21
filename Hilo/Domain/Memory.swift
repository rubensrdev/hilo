import Foundation

nonisolated struct MemoryID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

// contrato 8 + regla 1: un recuerdo sin relato no existe, y el relato nunca se reescribe
nonisolated struct Memory: Sendable, Identifiable {
  let id: MemoryID
  let narrative: String
  let date: MemoryDate?
  // fecha de sistema, nunca la del usuario; la pone quien guarda (F2), Domain no lee el reloj
  let savedAt: Date

  init?(narrative: String, date: MemoryDate? = nil, savedAt: Date) {
    guard !narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.id = MemoryID()
    self.narrative = narrative
    self.date = date
    self.savedAt = savedAt
  }

  // reconstruccion desde persistencia (F2.2): conserva el id ya validado al guardar, no crea uno nuevo
  init(id: MemoryID, narrative: String, date: MemoryDate? = nil, savedAt: Date) {
    self.id = id
    self.narrative = narrative
    self.date = date
    self.savedAt = savedAt
  }

  // regla 17: el año deducido solo ordena; desempate por guardado y, al final, por id para que el orden sea total
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
