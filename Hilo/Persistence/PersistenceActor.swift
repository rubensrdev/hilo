import Foundation
import SwiftData

@ModelActor
actor PersistenceActor {
  enum WriteError: Error, Equatable {
    case memoryNotFound
    case elementNotFound
  }

  // unico punto de escritura (contrato 2): las vistas nunca insertan, borran ni guardan
  func save(
    _ memory: Memory, photoData: Data? = nil, isAnalyzed: Bool, isExample: Bool
  ) throws -> MemoryID {
    // contrato 3 + DEC-27: los metadatos (incluida la ubicacion) se eliminan al guardar
    let strippedPhotoData = try photoData.map(PhotoStripper.stripMetadata(from:))
    let record = MemoryRecord(
      id: memory.id.value, narrative: memory.narrative, dateText: memory.date?.text,
      deducedYear: memory.date?.deducedYear, photoData: strippedPhotoData, savedAt: memory.savedAt,
      isAnalyzed: isAnalyzed, isExample: isExample)
    modelContext.insert(record)
    try modelContext.save()
    return memory.id
  }

  // contrato 1: el canonico lo calcula el dominio, la persistencia solo lo guarda
  func save(_ element: Element) throws -> ElementID {
    let record = ElementRecord(
      id: element.id.value, displayName: element.displayName,
      canonicalName: CanonicalName.of(element.displayName), type: element.type,
      aliases: element.aliases)
    modelContext.insert(record)
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

  // extraccion de valores Sendable (contrato 2): el dominio nunca ve un @Model
  func fetchMemories() throws -> [Memory] {
    try modelContext.fetch(FetchDescriptor<MemoryRecord>()).map(Self.memory(from:))
  }

  func fetchElements() throws -> [Element] {
    try modelContext.fetch(FetchDescriptor<ElementRecord>()).map(Self.element(from:))
  }

  func fetchAppearances() throws -> [Appearance] {
    try modelContext.fetch(FetchDescriptor<AppearanceRecord>()).compactMap(Self.appearance(from:))
  }

  // la foto no es del dominio (F1); sale como Data simple, ya Sendable por si misma
  func photoData(for id: MemoryID) throws -> Data? {
    try fetchMemoryRecord(id: id)?.photoData
  }

  // contrato 4: el cascade borra apariciones y foto; el dominio decide los huerfanos (reglas 11+12)
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

  // contrato 5 + B11: contenido fijo, resuelto contra los elementos ya existentes (F1 contrato 3)
  func loadExampleMemory(language: ExampleMemoryLanguage, loadedAt: Date) throws {
    guard try fetchExampleMemoryRecords().isEmpty else { return }
    var knownElements = try fetchElements()
    for seed in ExampleMemoryContent.seeds(for: language) {
      let date = seed.dateText.flatMap { MemoryDate(text: $0, deducedYear: seed.deducedYear) }
      let memory = Memory(id: MemoryID(), narrative: seed.narrative, date: date, savedAt: loadedAt)
      let memoryID = try save(memory, isAnalyzed: true, isExample: true)
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

  // contrato 6 + B11: el cascade borra apariciones; el dominio decide que elemento sobrevive
  func deleteExampleMemory() throws {
    for record in try fetchExampleMemoryRecords() {
      modelContext.delete(record)
    }
    try modelContext.save()
    try cleanOrphanedElements()
  }

  private func fetchExampleMemoryRecords() throws -> [MemoryRecord] {
    try modelContext.fetch(FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.isExample }))
  }

  private func fetchMemoryRecord(id: MemoryID) throws -> MemoryRecord? {
    // #Predicate exige capturar un valor simple, no acceder a .value del struct dentro del closure
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

  private static func element(from record: ElementRecord) -> Element {
    Element(
      id: ElementID(value: record.id), displayName: record.displayName, type: record.type,
      aliases: record.aliases)
  }

  // sin memoria o elemento (relacion rota), no hay Aparicion valida que devolver
  private static func appearance(from record: AppearanceRecord) -> Appearance? {
    guard let memoryID = record.memory?.id, let elementID = record.element?.id else { return nil }
    return Appearance(
      memoryID: MemoryID(value: memoryID), elementID: ElementID(value: elementID),
      role: record.role.flatMap(ElementRole.init), status: record.status)
  }
}
