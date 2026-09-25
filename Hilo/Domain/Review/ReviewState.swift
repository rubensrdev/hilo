/// Pure and recomputed live on every action; nothing is persisted here.
nonisolated struct ReviewState: Sendable {
  private(set) var items: [ReviewItem]
  let knownElements: [Element]
  let appearances: [Appearance]
  let excludingMemoryID: MemoryID?  // the memory under review, when understanding later
  let extractedDateText: String?
  let extractedDeducedYear: Int?

  init(
    candidates: [ReviewCandidate], extractedDateText: String?, extractedDeducedYear: Int?,
    knownElements: [Element], appearances: [Appearance], excludingMemoryID: MemoryID? = nil
  ) {
    self.items = Self.firstMentions(of: candidates).map { candidate in
      ReviewItem(
        id: ReviewItemID(), originalName: candidate.name, type: candidate.type,
        role: candidate.role,
        identity: ReviewIdentity(
          ElementResolution.resolving(
            name: candidate.name, type: candidate.type, against: knownElements)),
        isRemoved: false, pendingName: nil)
    }
    self.knownElements = knownElements
    self.appearances = appearances
    self.excludingMemoryID = excludingMemoryID
    self.extractedDateText = extractedDateText
    self.extractedDeducedYear = extractedDeducedYear
  }

  /// Two mentions of one element in a memory are one row; the first mention's role wins.
  private static func firstMentions(of candidates: [ReviewCandidate]) -> [ReviewCandidate] {
    var seen: Set<String> = []
    return candidates.filter { candidate in
      seen.insert("\(candidate.type.rawValue)|\(CanonicalName.of(candidate.name))").inserted
    }
  }

  // MARK: effective category — the block an item is in now, not when it was extracted

  private nonisolated enum Category { case new, known, doubtful, removed }

  private func category(of item: ReviewItem) -> Category {
    guard !item.isRemoved else { return .removed }
    switch item.identity {
    case .new:
      return .new
    case .recognized(_, let rejected):
      return rejected ? .new : .known
    case .doubt(_, let answer):
      switch answer {
      case .same(_): return .known
      case .notTheSame: return .new
      case nil: return .doubtful
      }
    }
  }

  /// The real ElementIDs of a known item: the whole recognition, or only the confirmed doubt.
  private func knownElementIDs(of identity: ReviewIdentity) -> Set<ElementID> {
    switch identity {
    case .recognized(let ids, _):
      return ids
    case .doubt(_, .same(let id)):
      return [id]
    default:
      return []
    }
  }

  // MARK: actions

  /// Rule 3: every merge can be rejected, a confirmed doubt included. Rejecting drops any pending
  /// rename, so the new element keeps the extracted name.
  mutating func rejectRecognition(_ itemID: ReviewItemID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    switch items[index].identity {
    case .recognized(let ids, false):
      items[index].identity = .recognized(ids, rejected: true)
      items[index].pendingName = nil
    case .doubt(let candidates, .same):
      items[index].identity = .doubt(candidates: candidates, answer: .notTheSame)
      items[index].pendingName = nil
    default:
      return
    }
  }

  mutating func confirmDoubt(_ itemID: ReviewItemID, as elementID: ElementID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    guard case .doubt(let candidates, _) = items[index].identity else { return }
    items[index].identity = .doubt(candidates: candidates, answer: .same(elementID))
  }

  mutating func rejectDoubt(_ itemID: ReviewItemID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    guard case .doubt(let candidates, _) = items[index].identity else { return }
    items[index].identity = .doubt(candidates: candidates, answer: .notTheSame)
  }

  mutating func remove(_ itemID: ReviewItemID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    items[index].isRemoved = true
  }

  mutating func restore(_ itemID: ReviewItemID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    items[index].isRemoved = false
  }

  /// Checks the effective category, not the original identity.
  @discardableResult
  mutating func rename(_ itemID: ReviewItemID, to newName: String) -> RenameOutcome {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return .applied }
    let item = items[index]

    switch category(of: item) {
    case .known:
      let existingIDs = knownElementIDs(of: item.identity)
      for id in existingIDs {
        if case .collidesWith(let other) = NameCollision.checking(
          newName, type: item.type, excluding: id, against: knownElements)
        {
          return .blocked(other)
        }
      }
      if let sibling = collidingSibling(of: itemID, type: item.type, newName: newName) {
        return .blockedByReviewItem(sibling)
      }
      items[index].pendingName = newName
      return .applied

    case .new:
      switch ElementResolution.resolving(name: newName, type: item.type, against: knownElements) {
      case .exactMatch(let ids):
        items[index].pendingName = newName
        items[index].identity = .recognized(ids, rejected: false)
        return .becameRecognized(ids)
      case .new, .identityDoubt:
        // Now check what this review will create on save. Known collisions go first, so two renames to
        // the same known element don't block each other.
        if let sibling = collidingSibling(of: itemID, type: item.type, newName: newName) {
          return .blockedByReviewItem(sibling)
        }
        items[index].pendingName = newName
        return .applied
      }

    case .doubtful, .removed:
      // The UI never offers renaming here, so no collision check guards a path the view never takes.
      items[index].pendingName = newName
      return .applied
    }
  }

  /// The other side of a collision may not exist yet: any item that would create a new element
  /// counts, removed ones included, since they can still be restored.
  private func collidingSibling(of itemID: ReviewItemID, type: ElementType, newName: String)
    -> ReviewItemID?
  {
    let canonical = CanonicalName.of(newName)
    return items.first { sibling in
      sibling.id != itemID && sibling.type == type
        && wouldBecomeNewElement(sibling.identity)
        && CanonicalName.of(sibling.currentName) == canonical
    }?.id
  }

  /// Same criterion outcome() uses to decide whether an item creates a new element.
  private func wouldBecomeNewElement(_ identity: ReviewIdentity) -> Bool {
    switch identity {
    case .new:
      return true
    case .recognized(_, let rejected):
      return rejected
    case .doubt(_, let answer):
      switch answer {
      case .same: return false
      case .notTheSame, nil: return true
      }
    }
  }

  // MARK: derived — always computed from items, knownElements and appearances, never stored

  var blocks: ReviewBlocks {
    var understood: [ReviewBlocks.Understood] = []
    var known: [ReviewBlocks.Known] = []
    var doubtful: [ReviewBlocks.Doubtful] = []
    var removed: [ReviewBlocks.Understood] = []

    for item in items {
      switch category(of: item) {
      case .removed:
        removed.append(.init(id: item.id, name: item.currentName, type: item.type))
      case .new:
        understood.append(.init(id: item.id, name: item.currentName, type: item.type))
      case .known:
        let ids = knownElementIDs(of: item.identity)
        known.append(
          .init(
            id: item.id, elementIDs: ids, name: item.currentName, type: item.type,
            otherMemoriesCount: otherMemoriesCount(for: ids)))
      case .doubtful:
        guard case .doubt(let candidateIDs, let answer) = item.identity else { continue }
        let candidates = candidateIDs.compactMap { id -> ReviewBlocks.Doubtful.Candidate? in
          guard let element = knownElements.first(where: { $0.id == id }) else { return nil }
          return ReviewBlocks.Doubtful.Candidate(
            id: id, name: element.displayName, otherMemoriesCount: otherMemoriesCount(for: [id]))
        }
        doubtful.append(
          .init(
            id: item.id, name: item.currentName, type: item.type, candidates: candidates,
            answer: answer))
      }
    }

    return ReviewBlocks(
      understood: understood, known: known, doubtful: doubtful, removed: removed,
      isBeginning: known.isEmpty && !understood.isEmpty)
  }

  /// Distinct memories that already have the element, excluding the one under review.
  private func otherMemoriesCount(for elementIDs: Set<ElementID>) -> Int {
    Set(
      appearances
        .filter { elementIDs.contains($0.elementID) && $0.memoryID != excludingMemoryID }
        .map(\.memoryID)
    ).count
  }

  func outcome(memoryID: MemoryID, dateTextAtSave: String) -> ReviewOutcome {
    var elementsToCreate: [ReviewOutcome.NewElement] = []
    var confirmedAppearances: [ReviewOutcome.ConfirmedAppearance] = []
    var aliasesToAdd: [ReviewOutcome.AliasToAdd] = []
    var renamesToApply: [ReviewOutcome.RenameToApply] = []

    for item in items where !item.isRemoved {
      switch item.identity {
      case .new:
        if let created = newElement(for: item) { elementsToCreate.append(created) }

      case .recognized(let ids, let rejected):
        if rejected {
          if let created = newElement(for: item) { elementsToCreate.append(created) }
        } else {
          for id in ids {
            confirmedAppearances.append(.init(elementID: id, role: item.role))
            if let pendingName = item.pendingName {
              renamesToApply.append(.init(elementID: id, newName: pendingName))
            }
          }
        }

      case .doubt(_, let answer):
        switch answer {
        case .same(let id):
          confirmedAppearances.append(.init(elementID: id, role: item.role))
          if !isAlreadyKnown(name: item.currentName, as: id) {
            aliasesToAdd.append(.init(elementID: id, alias: item.currentName))
          }
          if let pendingName = item.pendingName {
            renamesToApply.append(.init(elementID: id, newName: pendingName))
          }
        case .notTheSame, nil:
          // Saving with an unanswered doubt keeps the elements separate.
          if let created = newElement(for: item) { elementsToCreate.append(created) }
        }
      }
    }

    let date = MemoryDate.resolving(
      extractedText: extractedDateText, deducedYear: extractedDeducedYear,
      textAtSave: dateTextAtSave)

    return ReviewOutcome(
      elementsToCreate: elementsToCreate, confirmedAppearances: confirmedAppearances,
      aliasesToAdd: aliasesToAdd, renamesToApply: renamesToApply, date: date)
  }

  private func newElement(for item: ReviewItem) -> ReviewOutcome.NewElement? {
    Element(displayName: item.currentName, type: item.type).map {
      ReviewOutcome.NewElement(element: $0, role: item.role)
    }
  }

  private func isAlreadyKnown(name: String, as elementID: ElementID) -> Bool {
    guard let element = knownElements.first(where: { $0.id == elementID }) else { return false }
    return element.matches(canonical: CanonicalName.of(name))
  }
}

nonisolated enum RenameOutcome: Sendable, Equatable {
  case applied
  case blocked(ElementID)
  case blockedByReviewItem(ReviewItemID)  // collides with another new element in this same review
  case becameRecognized(Set<ElementID>)
}

/// The review always groups people, places and objects, in that order.
extension ElementType {
  nonisolated static let reviewOrder: [ElementType] = [.person, .place, .object]
}

/// The review's four blocks, each present only when it has content.
nonisolated struct ReviewBlocks: Sendable, Equatable {
  nonisolated struct Understood: Sendable, Equatable, Identifiable {
    let id: ReviewItemID
    let name: String
    let type: ElementType
  }

  nonisolated struct Known: Sendable, Equatable, Identifiable {
    let id: ReviewItemID
    let elementIDs: Set<ElementID>
    let name: String
    let type: ElementType
    let otherMemoriesCount: Int
  }

  nonisolated struct Doubtful: Sendable, Equatable, Identifiable {
    /// Name and count already come from the domain, so the view doesn't repeat the rule.
    nonisolated struct Candidate: Sendable, Equatable, Identifiable {
      let id: ElementID
      let name: String
      let otherMemoriesCount: Int
    }

    let id: ReviewItemID
    let name: String
    let type: ElementType
    let candidates: [Candidate]
    let answer: DoubtAnswer?
  }

  let understood: [Understood]  // block 1
  let known: [Known]  // block 2
  let doubtful: [Doubtful]  // block 3
  let removed: [Understood]  // removed items stay visible in block 1 so they can be undone
  let isBeginning: Bool  // nothing known yet and something understood

  nonisolated struct UnderstoodRow: Sendable, Equatable, Identifiable {
    let id: ReviewItemID
    let name: String
    let type: ElementType
    let isRemoved: Bool
  }

  nonisolated struct UnderstoodGroup: Sendable, Equatable {
    let type: ElementType
    let rows: [UnderstoodRow]
  }

  /// Removed items count as content.
  var isNothingRecognized: Bool {
    understood.isEmpty && known.isEmpty && doubtful.isEmpty && removed.isEmpty
  }

  var showsUnderstood: Bool { !understood.isEmpty || !removed.isEmpty }

  /// Block 1 by type, in block order; removed items go last within each type.
  var understoodGroups: [UnderstoodGroup] {
    let rows =
      understood.map { UnderstoodRow(id: $0.id, name: $0.name, type: $0.type, isRemoved: false) }
      + removed.map { UnderstoodRow(id: $0.id, name: $0.name, type: $0.type, isRemoved: true) }
    return ElementType.reviewOrder.compactMap { type in
      let ofType = rows.filter { $0.type == type }
      return ofType.isEmpty ? nil : UnderstoodGroup(type: type, rows: ofType)
    }
  }

  /// Names in the block order above, stable within each type.
  var beginningNames: [String] {
    ElementType.reviewOrder.flatMap { type in understood.filter { $0.type == type }.map(\.name) }
  }
}

/// What confirming the review saves, without persisting anything.
nonisolated struct ReviewOutcome: Sendable, Equatable {
  nonisolated struct NewElement: Sendable, Equatable {
    let element: Element
    let role: ElementRole?
  }

  nonisolated struct ConfirmedAppearance: Sendable, Equatable {
    let elementID: ElementID
    let role: ElementRole?
  }

  nonisolated struct AliasToAdd: Sendable, Equatable {
    let elementID: ElementID
    let alias: String
  }

  nonisolated struct RenameToApply: Sendable, Equatable {
    let elementID: ElementID
    let newName: String
  }

  let elementsToCreate: [NewElement]
  let confirmedAppearances: [ConfirmedAppearance]
  let aliasesToAdd: [AliasToAdd]
  let renamesToApply: [RenameToApply]
  let date: MemoryDate?
}
