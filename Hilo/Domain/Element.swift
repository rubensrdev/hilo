import Foundation

nonisolated struct ElementID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

nonisolated enum ElementType: Sendable, Equatable {
  case person
  case place
  case object
}

// contrato 8: un elemento sin nombre no existe, y el nombre mostrado nunca se reescribe
nonisolated struct Element: Sendable, Identifiable {
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

  // compartido entre contrato 3 (resolucion) y contrato 5 (colision): mismo canonico en nombre o alias
  func matches(canonical: String) -> Bool {
    CanonicalName.of(displayName) == canonical
      || aliases.contains { CanonicalName.of($0) == canonical }
  }
}
