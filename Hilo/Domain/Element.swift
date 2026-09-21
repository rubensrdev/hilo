import Foundation

nonisolated struct ElementID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

// rawValue String + Codable: F2 lo persiste como columna, no como blob serializado
nonisolated enum ElementType: String, Sendable, Equatable, Codable {
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

  // reconstruccion desde persistencia (F2.2): conserva el id ya validado al guardar, no crea uno nuevo
  init(id: ElementID, displayName: String, type: ElementType, aliases: [String] = []) {
    self.id = id
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
