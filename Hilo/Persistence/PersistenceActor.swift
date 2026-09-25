import Foundation
import SwiftData

@ModelActor
actor PersistenceActor {
  enum WriteError: Error, Equatable {
    case memoryNotFound
    case elementNotFound
    case alreadyAnalyzed
  }

  /// The single write path: views never insert, delete or save.
  func save(
    _ memory: Memory, photoData: Data? = nil, isAnalyzed: Bool, isExample: Bool
  ) throws -> MemoryID {
    // Metadata, location included, is stripped on save.
    let strippedPhotoData = try photoData.map(PhotoStripper.stripMetadata(from:))
    let record = MemoryRecord(
      id: memory.id.value, narrative: memory.narrative, dateText: memory.date?.text,
      deducedYear: memory.date?.deducedYear, photoData: strippedPhotoData, savedAt: memory.savedAt,
      isAnalyzed: isAnalyzed, isExample: isExample)
    modelContext.insert(record)
    do {
      try modelContext.save()
    } catch {
      // As in saveReviewed: a failed save leaves nothing pending for the next write.
      modelContext.rollback()
      throw error
    }
    return memory.id
  }

  /// The domain computes the canonical name; persistence only stores it.
  func save(_ element: Element) throws -> ElementID {
    modelContext.insert(Self.elementRecord(from: element))
    try modelContext.save()
    return element.id
  }

  func save(_ appearance: Appearance) throws {
    guard let memoryRecord = try fetchMemoryRecord(id: appearance.memoryID) else {
      throw WriteError.memoryNotFound
    }
    guard let elementRecord = try fetchElementRecord(id: appearance.elementID) else {
      throw WriteError.elementNotFound
    }
    let record = AppearanceRecord(
      memory: memoryRecord, element: elementRecord, role: appearance.role?.text,
      status: appearance.status)
    modelContext.insert(record)
    try modelContext.save()
  }

  /// The whole ReviewOutcome in one save: if anything fails midway, nothing is left half-done.
  func saveReviewed(_ memory: Memory, photoData: Data?, outcome: ReviewOutcome) throws -> MemoryID {
    do {
      // The date always comes from the outcome, the only place that applies the year rule.
      let record = MemoryRecord(
        id: memory.id.value, narrative: memory.narrative, dateText: outcome.date?.text,
        deducedYear: outcome.date?.deducedYear,
        photoData: try photoData.map(PhotoStripper.stripMetadata(from:)), savedAt: memory.savedAt,
        isAnalyzed: true, isExample: false)
      modelContext.insert(record)
      try apply(outcome, to: record)
      try modelContext.save()
      return memory.id
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  /// Understanding later updates the same memory, without touching savedAt or the photo.
  func completeAnalysis(of id: MemoryID, outcome: ReviewOutcome) throws {
    do {
      guard let record = try fetchMemoryRecord(id: id) else { throw WriteError.memoryNotFound }
      // Check and write in the same actor hop, so capture and detail can't analyse it twice.
      guard !record.isAnalyzed else { throw WriteError.alreadyAnalyzed }
      record.dateText = outcome.date?.text
      record.deducedYear = outcome.date?.deducedYear
      record.isAnalyzed = true
      try apply(outcome, to: record)
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  private func apply(_ outcome: ReviewOutcome, to memoryRecord: MemoryRecord) throws {
    for created in outcome.elementsToCreate {
      let elementRecord = Self.elementRecord(from: created.element)
      modelContext.insert(elementRecord)
      insertConfirmedAppearance(memory: memoryRecord, element: elementRecord, role: created.role)
    }
    for confirmed in outcome.confirmedAppearances {
      guard let elementRecord = try fetchElementRecord(id: confirmed.elementID) else {
        throw WriteError.elementNotFound
      }
      insertConfirmedAppearance(memory: memoryRecord, element: elementRecord, role: confirmed.role)
    }
    for alias in outcome.aliasesToAdd {
      guard let elementRecord = try fetchElementRecord(id: alias.elementID) else {
        throw WriteError.elementNotFound
      }
      elementRecord.aliases.append(alias.alias)
    }
    // Rule 10: there is one element, so renaming it renames it in all its memories.
    for rename in outcome.renamesToApply {
      guard let elementRecord = try fetchElementRecord(id: rename.elementID) else {
        throw WriteError.elementNotFound
      }
      elementRecord.displayName = rename.newName
      elementRecord.canonicalName = CanonicalName.of(rename.newName)
    }
  }

  private func insertConfirmedAppearance(
    memory: MemoryRecord, element: ElementRecord, role: ElementRole?
  ) {
    modelContext.insert(
      AppearanceRecord(
        memory: memory, element: element, role: role?.text, status: .confirmedByUser))
  }

  /// Extracts Sendable values: the domain never sees an @Model.
  func fetchMemories() throws -> [Memory] {
    try modelContext.fetch(FetchDescriptor<MemoryRecord>()).map(Self.memory(from:))
  }

  func fetchElements() throws -> [Element] {
    try modelContext.fetch(FetchDescriptor<ElementRecord>()).map(Self.element(from:))
  }

  func fetchAppearances() throws -> [Appearance] {
    try modelContext.fetch(FetchDescriptor<AppearanceRecord>()).compactMap(Self.appearance(from:))
  }

  /// Computed here: one actor hop, everything read from the same store state.
  func connectionMoment(for id: MemoryID) throws -> ConnectionMoment? {
    try ConnectionMoment(
      savedMemoryID: id, memories: fetchMemories(), elements: fetchElements(),
      appearances: fetchAppearances())
  }

  /// Only an unanalyzed memory can be understood later.
  func unanalyzedMemory(id: MemoryID) throws -> Memory? {
    guard let record = try fetchMemoryRecord(id: id), !record.isAnalyzed else { return nil }
    return Self.memory(from: record)
  }

  /// The photo isn't part of the domain; it leaves as plain Data, already Sendable.
  func photoData(for id: MemoryID) throws -> Data? {
    try fetchMemoryRecord(id: id)?.photoData
  }

  /// Editing the text never re-analyses and leaves date, photo and appearances alone.
  func editNarrative(id: MemoryID, narrative: String) throws {
    guard let record = try fetchMemoryRecord(id: id) else { throw WriteError.memoryNotFound }
    record.narrative = narrative
    try modelContext.save()
  }

  /// Rule 10: renaming changes the element across the whole memory. The domain has already
  /// rejected any collision.
  func renameElement(id: ElementID, newName: String) throws {
    guard let record = try fetchElementRecord(id: id) else { throw WriteError.elementNotFound }
    record.displayName = newName
    record.canonicalName = CanonicalName.of(newName)
    try modelContext.save()
  }

  /// The domain has already rejected any collision.
  func addAlias(id: ElementID, alias: String) throws {
    guard let record = try fetchElementRecord(id: id) else { throw WriteError.elementNotFound }
    record.aliases.append(alias)
    try modelContext.save()
  }

  /// The cascade deletes appearances and photo; the domain decides the orphans (rules 11 and 12).
  func deleteMemory(id: MemoryID) throws {
    guard let record = try fetchMemoryRecord(id: id) else { throw WriteError.memoryNotFound }
    modelContext.delete(record)
    try modelContext.save()
    try cleanOrphanedElements()
  }

  private func cleanOrphanedElements() throws {
    let orphans = OrphanElements.among(try fetchElements(), appearances: try fetchAppearances())
    for id in orphans {
      if let record = try fetchElementRecord(id: id) {
        modelContext.delete(record)
      }
    }
    try modelContext.save()
  }

  /// Fixed content, resolved against the elements that already exist.
  func loadExampleMemory(language: ExampleMemoryLanguage, loadedAt: Date) throws {
    guard try fetchExampleMemoryRecords().isEmpty else { return }
    try insertSeeds(ExampleMemoryContent.seeds(for: language), isExample: true, loadedAt: loadedAt)
  }

  #if DEBUG
    /// Adds two memories to the example for docs/validacion-manual. Never in Release; same
    /// idempotency guard as loadExampleMemory.
    func loadDebugValidationDataset(loadedAt: Date) throws {
      guard try fetchExampleMemoryRecords().isEmpty else { return }
      try insertSeeds(
        ExampleMemoryContent.seeds(for: .spanish) + DebugValidationContent.seeds,
        isExample: true, loadedAt: loadedAt)
    }
  #endif

  private func insertSeeds(_ seeds: [ExampleMemorySeed], isExample: Bool, loadedAt: Date) throws {
    var knownElements = try fetchElements()
    for seed in seeds {
      let date = seed.dateText.flatMap { MemoryDate(text: $0, deducedYear: seed.deducedYear) }
      let memory = Memory(id: MemoryID(), narrative: seed.narrative, date: date, savedAt: loadedAt)
      let memoryID = try save(memory, isAnalyzed: true, isExample: isExample)
      for appearanceSeed in seed.appearances {
        let elementID: ElementID
        switch ElementResolution.resolving(
          name: appearanceSeed.displayName, type: appearanceSeed.type, against: knownElements
        ) {
        case .exactMatch(let ids):
          guard let id = ids.first else { continue }
          elementID = id
        case .new, .identityDoubt:
          let element = Element(
            id: ElementID(), displayName: appearanceSeed.displayName, type: appearanceSeed.type)
          elementID = try save(element)
          knownElements.append(element)
        }
        try save(
          Appearance(
            memoryID: memoryID, elementID: elementID,
            role: appearanceSeed.role.flatMap(ElementRole.init), status: .confirmedByUser))
      }
    }
  }

  /// The cascade deletes appearances; the domain decides which elements survive.
  func deleteExampleMemory() throws {
    for record in try fetchExampleMemoryRecords() {
      modelContext.delete(record)
    }
    try modelContext.save()
    try cleanOrphanedElements()
  }

  func hasExampleMemory() throws -> Bool {
    try !fetchExampleMemoryRecords().isEmpty
  }

  private func fetchExampleMemoryRecords() throws -> [MemoryRecord] {
    try modelContext.fetch(FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.isExample }))
  }

  /// Rule 25: a full wipe, with nothing left in the store or in the external photo storage.
  func wipeAllData() throws {
    for record in try modelContext.fetch(FetchDescriptor<MemoryRecord>()) {
      modelContext.delete(record)
    }
    for record in try modelContext.fetch(FetchDescriptor<ElementRecord>()) {
      modelContext.delete(record)
    }
    for record in try modelContext.fetch(FetchDescriptor<DiscardRecord>()) {
      modelContext.delete(record)
    }
    try modelContext.save()
  }

  private func fetchMemoryRecord(id: MemoryID) throws -> MemoryRecord? {
    // #Predicate needs a plain captured value, not .value read inside the closure.
    let targetID = id.value
    var descriptor = FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == targetID })
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func fetchElementRecord(id: ElementID) throws -> ElementRecord? {
    let targetID = id.value
    var descriptor = FetchDescriptor<ElementRecord>(predicate: #Predicate { $0.id == targetID })
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private static func memory(from record: MemoryRecord) -> Memory {
    let date = record.dateText.flatMap { MemoryDate(text: $0, deducedYear: record.deducedYear) }
    return Memory(
      id: MemoryID(value: record.id), narrative: record.narrative, date: date,
      savedAt: record.savedAt)
  }

  private static func elementRecord(from element: Element) -> ElementRecord {
    ElementRecord(
      id: element.id.value, displayName: element.displayName,
      canonicalName: CanonicalName.of(element.displayName), type: element.type,
      aliases: element.aliases)
  }

  private static func element(from record: ElementRecord) -> Element {
    Element(
      id: ElementID(value: record.id), displayName: record.displayName, type: record.type,
      aliases: record.aliases)
  }

  /// With no memory or element (a broken relationship) there is no valid Appearance.
  private static func appearance(from record: AppearanceRecord) -> Appearance? {
    guard let memoryID = record.memory?.id, let elementID = record.element?.id else { return nil }
    return Appearance(
      memoryID: MemoryID(value: memoryID), elementID: ElementID(value: elementID),
      role: record.role.flatMap(ElementRole.init), status: record.status)
  }
}
