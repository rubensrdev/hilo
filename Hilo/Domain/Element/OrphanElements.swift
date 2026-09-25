/// Rules 9, 11 and 12: an element with no appearances left stops existing.
nonisolated enum OrphanElements {
  static func among(_ elements: [Element], appearances: [Appearance]) -> [ElementID] {
    let referenced = Set(appearances.map(\.elementID))
    return elements.map(\.id).filter { !referenced.contains($0) }
  }
}
