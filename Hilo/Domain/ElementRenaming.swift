// contrato 5 (DEC-26): renombrar o añadir alias colisiona si el canonico ya pertenece a otro elemento del mismo tipo
nonisolated enum NameCollision: Sendable, Equatable {
  case none
  case collidesWith(ElementID)

  static func checking(
    _ name: String, type: ElementType, excluding elementID: ElementID, against elements: [Element]
  ) -> NameCollision {
    let canonical = CanonicalName.of(name)
    let colliding = elements.first { element in
      guard element.id != elementID, element.type == type else { return false }
      return element.matches(canonical: canonical)
    }
    if let colliding {
      return .collidesWith(colliding.id)
    }
    return .none
  }
}

nonisolated enum ElementRenaming {
  static func affectedMemories(_ elementID: ElementID, appearances: [Appearance]) -> Int {
    Set(appearances.filter { $0.elementID == elementID }.map(\.memoryID)).count
  }
}
