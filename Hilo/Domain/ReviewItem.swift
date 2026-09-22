import Foundation

nonisolated struct ReviewItemID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

// contrato 3: entrada de dominio para un candidato extraido, sin saber nada de FoundationModels
nonisolated struct ReviewCandidate: Sendable {
  let name: String
  let type: ElementType
  let role: ElementRole?

  init?(name: String, type: ElementType, role: ElementRole?) {
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    self.name = name
    self.type = type
    self.role = role
  }
}

// contrato 3: como responde el usuario a una duda de identidad, dos respuestas del mismo peso
nonisolated enum DoubtAnswer: Sendable, Equatable {
  case same(ElementID)
  case notTheSame
}

// contrato 3: clasificacion de un candidato, con la respuesta del usuario cuando aplica
nonisolated enum ReviewIdentity: Sendable, Equatable {
  case new
  case recognized(Set<ElementID>, rejected: Bool)  // regla 6: rechazar crea un elemento nuevo
  case doubt(candidates: Set<ElementID>, answer: DoubtAnswer?)  // regla 7, o separados si no se responde

  init(_ resolution: ElementResolution) {
    switch resolution {
    case .new:
      self = .new
    case .exactMatch(let ids):
      self = .recognized(ids, rejected: false)
    case .identityDoubt(let ids):
      self = .doubt(candidates: ids, answer: nil)
    }
  }
}

// una fila de la revision: el candidato mas las acciones del usuario aplicadas hasta ahora
nonisolated struct ReviewItem: Sendable, Identifiable {
  let id: ReviewItemID
  let originalName: String
  let type: ElementType
  let role: ElementRole?
  var identity: ReviewIdentity
  var isRemoved: Bool  // DEC-17: quitar/deshacer, independiente de la identidad
  var pendingName: String?  // DEC-40: renombrado pendiente, nil = sin cambios

  var currentName: String { pendingName ?? originalName }
}
