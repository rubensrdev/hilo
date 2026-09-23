import Foundation

// contrato 7 + regla 17: el texto es lo unico que se muestra, el año solo ordena y agrupa
nonisolated struct MemoryDate: Sendable, Equatable {
  let text: String
  let deducedYear: Int?

  init?(text: String, deducedYear: Int? = nil) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.text = text
    self.deducedYear = deducedYear
  }

  // contrato 2 (DEC-44): el año deducido solo sobrevive si el texto no cambio ni un espacio
  static func resolving(extractedText: String?, deducedYear: Int?, textAtSave: String)
    -> MemoryDate?
  {
    let trimmed = textAtSave.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }  // borrado
    guard extractedText == trimmed else { return MemoryDate(text: trimmed, deducedYear: nil) }  // editado / a mano
    return MemoryDate(text: trimmed, deducedYear: deducedYear)  // sin cambiar
  }
}
