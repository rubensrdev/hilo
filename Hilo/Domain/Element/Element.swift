import Foundation

nonisolated struct ElementID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

/// Raw String value, so persistence stores it as a column, not a serialized blob.
nonisolated enum ElementType: String, Sendable, Equatable, Codable {
  case person
  case place
  case object
}

/// An element without a name does not exist, and its display name is never rewritten.
nonisolated struct Element: Sendable, Identifiable, Equatable {
  let id: ElementID
  let displayName: String
  let type: ElementType
  let aliases: [String]

  init?(displayName: String, type: ElementType, aliases: [String] = []) {
    guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.id = ElementID()
    self.displayName = displayName
    self.type = type
    self.aliases = aliases
  }

  /// Rebuilds from persistence, keeping the id validated at save time.
  init(id: ElementID, displayName: String, type: ElementType, aliases: [String] = []) {
    self.id = id
    self.displayName = displayName
    self.type = type
    self.aliases = aliases
  }

  /// Shared by resolution and collision checks: the same canonical name in the name or an alias.
  func matches(canonical: String) -> Bool {
    CanonicalName.of(displayName) == canonical
      || aliases.contains { CanonicalName.of($0) == canonical }
  }
}
