import Foundation

/// Rule 17: only the text is shown; the year only sorts and groups.
nonisolated struct MemoryDate: Sendable, Equatable {
  let text: String
  let deducedYear: Int?

  init?(text: String, deducedYear: Int? = nil) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.text = text
    self.deducedYear = deducedYear
  }

  /// The deduced year survives only if the text is saved exactly as extracted, down to a space.
  static func resolving(extractedText: String?, deducedYear: Int?, textAtSave: String)
    -> MemoryDate?
  {
    let trimmed = textAtSave.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }  // cleared
    guard extractedText == trimmed else { return MemoryDate(text: trimmed, deducedYear: nil) }  // edited or hand-typed
    return MemoryDate(text: trimmed, deducedYear: deducedYear)  // unchanged
  }
}
