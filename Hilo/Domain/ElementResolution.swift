// contrato 3: dado un nombre, un tipo y los elementos existentes, exactamente uno de estos tres resultados, sin efectos
nonisolated enum ElementResolution: Sendable, Equatable {
  case exactMatch(Set<ElementID>)
  case identityDoubt(Set<ElementID>)
  case new

  static func resolving(name: String, type: ElementType, against elements: [Element])
    -> ElementResolution
  {
    let canonical = CanonicalName.of(name)
    let sameType = elements.filter { $0.type == type }

    let exact = sameType.filter { element in
      CanonicalName.of(element.displayName) == canonical
        || element.aliases.contains { CanonicalName.of($0) == canonical }
    }
    if !exact.isEmpty {
      return .exactMatch(Set(exact.map(\.id)))
    }

    // regla 5+8: la duda solo aplica cuando no hubo ya una coincidencia exacta
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
