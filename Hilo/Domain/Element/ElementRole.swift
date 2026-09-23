import Foundation

// contrato 8: el papel es texto libre del usuario, igual que el nombre nunca se reescribe
nonisolated struct ElementRole: Sendable, Equatable {
  let text: String

  init?(text: String) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.text = text
  }
}
