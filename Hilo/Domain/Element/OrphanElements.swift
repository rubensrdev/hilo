// contrato 6, reglas 9+11+12: un elemento sin ninguna aparicion deja de existir
nonisolated enum OrphanElements {
  static func among(_ elements: [Element], appearances: [Appearance]) -> [ElementID] {
    let referenced = Set(appearances.map(\.elementID))
    return elements.map(\.id).filter { !referenced.contains($0) }
  }
}
