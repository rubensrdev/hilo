/// Exactly one of three outcomes, with no side effects.
nonisolated enum ElementResolution: Sendable, Equatable {
  case exactMatch(Set<ElementID>)
  case identityDoubt(Set<ElementID>)
  case new

  static func resolving(name: String, type: ElementType, against elements: [Element])
    -> ElementResolution
  {
    let canonical = CanonicalName.of(name)
    let sameType = elements.filter { $0.type == type }

    let exact = sameType.filter { $0.matches(canonical: canonical) }
    if !exact.isEmpty {
      return .exactMatch(Set(exact.map(\.id)))
    }

    // Rules 5 and 8: doubt only applies when there was no exact match.
    let doubtful = sameType.filter { element in
      Resemblance.between(name, type: type, element.displayName, type: element.type)
        || element.aliases.contains {
          Resemblance.between(name, type: type, $0, type: element.type)
        }
    }
    if !doubtful.isEmpty {
      return .identityDoubt(Set(doubtful.map(\.id)))
    }

    return .new
  }
}
