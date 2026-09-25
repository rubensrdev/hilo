import Foundation

/// Free text from the user, never rewritten, like the element's name.
nonisolated struct ElementRole: Sendable, Equatable {
  let text: String

  init?(text: String) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.text = text
  }
}
