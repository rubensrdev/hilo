// contrato 2 + contrato 4: el estado de la revision (S3), puro y recalculado en vivo
nonisolated struct ReviewState: Sendable {
  private(set) var items: [ReviewItem]
  let knownElements: [Element]
  let appearances: [Appearance]
  let excludingMemoryID: MemoryID?  // DEC-22 y "comprender mas tarde" (F4.5)
  let extractedDateText: String?
  let extractedDeducedYear: Int?

  init(
    candidates: [ReviewCandidate], extractedDateText: String?, extractedDeducedYear: Int?,
    knownElements: [Element], appearances: [Appearance], excludingMemoryID: MemoryID? = nil
  ) {
    self.items = candidates.map { candidate in
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

  // MARK: categoria efectiva — de que bloque es un item ahora mismo, no en el momento de extraerlo

  private enum Category { case new, known, doubtful, removed }

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

  // los ElementID reales de un item ya conocido: el reconocimiento entero, o solo la duda confirmada
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

  // MARK: acciones — regla 3+9+17, nada se persiste aqui, solo se recalcula en vivo

  mutating func rejectRecognition(_ itemID: ReviewItemID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    guard case .recognized(let ids, false) = items[index].identity else { return }
    items[index].identity = .recognized(ids, rejected: true)
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

  // DEC-40/DEC-26/DEC-41: mira la categoria efectiva, no la identidad original
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
      items[index].pendingName = newName
      return .applied

    case .new:
      switch ElementResolution.resolving(name: newName, type: item.type, against: knownElements) {
      case .exactMatch(let ids):
        items[index].pendingName = newName
        items[index].identity = .recognized(ids, rejected: false)
        return .becameRecognized(ids)
      case .new, .identityDoubt:
        items[index].pendingName = newName
        return .applied
      }

    case .doubtful, .removed:
      // la UI nunca ofrece renombrar aqui: se aplica sin comprobar colision (regla del proyecto,
      // no se valida un camino que la vista no toma)
      items[index].pendingName = newName
      return .applied
    }
  }

  // MARK: derivado — siempre calculado de items+knownElements+appearances, nunca almacenado

  var blocks: ReviewBlocks {
    var understood: [ReviewBlocks.Understood] = []
    var known: [ReviewBlocks.Known] = []
    var doubtful: [ReviewBlocks.Doubtful] = []

    for item in items {
      switch category(of: item) {
      case .removed:
        continue
      case .new:
        understood.append(.init(id: item.id, name: item.currentName, type: item.type))
      case .known:
        let ids = knownElementIDs(of: item.identity)
        known.append(
          .init(
            id: item.id, elementIDs: ids, name: item.currentName, type: item.type,
            otherMemoriesCount: otherMemoriesCount(for: ids)))
      case .doubtful:
        guard case .doubt(let candidates, let answer) = item.identity else { continue }
        doubtful.append(
          .init(
            id: item.id, name: item.currentName, type: item.type, candidates: candidates,
            answer: answer))
      }
    }

    return ReviewBlocks(
      understood: understood, known: known, doubtful: doubtful,
      isBeginning: known.isEmpty && !understood.isEmpty)
  }

  // DEC-22: recuerdos distintos que ya tienen el elemento, sin contar el que se esta revisando
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
          // contrato 3: guardar sin responder una duda deja los elementos separados
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
  case becameRecognized(Set<ElementID>)
}

// contrato 2 + §9.2: los cuatro bloques de la revision, cada uno solo si tiene contenido
nonisolated struct ReviewBlocks: Sendable, Equatable {
  struct Understood: Sendable, Equatable, Identifiable {
    let id: ReviewItemID
    let name: String
    let type: ElementType
  }

  struct Known: Sendable, Equatable, Identifiable {
    let id: ReviewItemID
    let elementIDs: Set<ElementID>
    let name: String
    let type: ElementType
    let otherMemoriesCount: Int  // DEC-22
  }

  struct Doubtful: Sendable, Equatable, Identifiable {
    let id: ReviewItemID
    let name: String
    let type: ElementType
    let candidates: Set<ElementID>
    let answer: DoubtAnswer?
  }

  let understood: [Understood]  // bloque 1
  let known: [Known]  // bloque 2
  let doubtful: [Doubtful]  // bloque 3
  let isBeginning: Bool  // contrato 2: known vacio y understood no vacio
}

// contrato 3+5 (regla 3, regla 7, DEC-40): lo que se guarda al confirmar la revision, sin persistir nada
nonisolated struct ReviewOutcome: Sendable, Equatable {
  struct NewElement: Sendable, Equatable {
    let element: Element
    let role: ElementRole?
  }

  struct ConfirmedAppearance: Sendable, Equatable {
    let elementID: ElementID
    let role: ElementRole?
  }

  struct AliasToAdd: Sendable, Equatable {
    let elementID: ElementID
    let alias: String
  }

  struct RenameToApply: Sendable, Equatable {
    let elementID: ElementID
    let newName: String
  }

  let elementsToCreate: [NewElement]
  let confirmedAppearances: [ConfirmedAppearance]
  let aliasesToAdd: [AliasToAdd]
  let renamesToApply: [RenameToApply]
  let date: MemoryDate?
}
