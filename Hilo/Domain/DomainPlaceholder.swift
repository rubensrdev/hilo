import Foundation

// contrato 2: prueba el aislamiento nonisolated que sostendra el dominio real de F1;
// se borra cuando F1 traiga los primeros tipos de Domain de verdad
nonisolated struct DomainPlaceholder: Sendable {
  let value: Int
}

nonisolated func doublePlaceholderValue(_ placeholder: DomainPlaceholder) -> Int {
  placeholder.value * 2
}
