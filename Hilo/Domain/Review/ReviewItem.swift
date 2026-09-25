import Foundation

nonisolated struct ReviewItemID: Sendable, Hashable {
  let value: UUID

  init(value: UUID = UUID()) {
    self.value = value
  }
}

/// A candidate as the domain sees it, knowing nothing about FoundationModels.
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

/// Two answers of equal weight to an identity doubt.
nonisolated enum DoubtAnswer: Sendable, Equatable {
  case same(ElementID)
  case notTheSame
}

nonisolated enum ReviewIdentity: Sendable, Equatable {
  case new
  case recognized(Set<ElementID>, rejected: Bool)  // Rule 6: rejecting creates a new element
  case doubt(candidates: Set<ElementID>, answer: DoubtAnswer?)  // Rule 7; left separate if unanswered

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

/// A review row: the candidate plus the user's actions so far.
nonisolated struct ReviewItem: Sendable, Identifiable {
  let id: ReviewItemID
  let originalName: String
  let type: ElementType
  let role: ElementRole?
  var identity: ReviewIdentity
  var isRemoved: Bool  // remove/undo, independent of identity
  var pendingName: String?  // applied on save; nil means unchanged

  var currentName: String { pendingName ?? originalName }
}
