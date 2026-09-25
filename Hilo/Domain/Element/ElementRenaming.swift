/// Renaming or adding an alias collides when the canonical name already belongs to another
/// element of the same type.
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
