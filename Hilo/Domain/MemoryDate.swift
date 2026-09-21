import Foundation

// contrato 7 + regla 17: el texto es lo unico que se muestra, el año solo ordena y agrupa
nonisolated struct MemoryDate: Sendable {
  let text: String
  let deducedYear: Int?

  init?(text: String, deducedYear: Int? = nil) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.text = text
    self.deducedYear = deducedYear
  }
}
