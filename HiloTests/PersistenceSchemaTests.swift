import Foundation
import SwiftData
import Testing

@testable import Hilo

// mecanica de SwiftData: guardar, relacionar, recuperar, cascada — sin reglas de dominio
struct PersistenceSchemaTests {
  @Test func `In-memory container is created without throwing and has the four persisted entities`()
    throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    #expect(container.schema.entities.count == 4)
  }

  @Test func `A memory can be saved and fetched with no photo, no date and no elements`() throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let context = ModelContext(container)
    let savedAt = Date(timeIntervalSince1970: 0)
    let record = MemoryRecord(
      narrative: "Aprendí a montar en bici en el parque de al lado.", savedAt: savedAt)
    context.insert(record)
    try context.save()

    let fetched = try #require(try context.fetch(FetchDescriptor<MemoryRecord>()).first)
    #expect(fetched.narrative == "Aprendí a montar en bici en el parque de al lado.")
    #expect(fetched.dateText == nil)
    #expect(fetched.deducedYear == nil)
    #expect(fetched.photoData == nil)
    #expect(fetched.appearances.isEmpty)
  }

  @Test func `isAnalyzed distinguishes two memories that both have zero appearances`() throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let context = ModelContext(container)
    let savedAt = Date(timeIntervalSince1970: 0)
    let analyzed = MemoryRecord(
      narrative: "Recuerdo analizado.", savedAt: savedAt, isAnalyzed: true)
    let unanalyzed = MemoryRecord(
      narrative: "Recuerdo sin analizar.", savedAt: savedAt, isAnalyzed: false)
    context.insert(analyzed)
    context.insert(unanalyzed)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<MemoryRecord>())
    let fetchedAnalyzed = try #require(fetched.first { $0.narrative == "Recuerdo analizado." })
    let fetchedUnanalyzed = try #require(
      fetched.first { $0.narrative == "Recuerdo sin analizar." })

    #expect(fetchedAnalyzed.appearances.isEmpty)
    #expect(fetchedUnanalyzed.appearances.isEmpty)
    #expect(fetchedAnalyzed.isAnalyzed)
    #expect(!fetchedUnanalyzed.isAnalyzed)
  }

  @Test func `An element with aliases persists and is fetched with the same aliases`() throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let context = ModelContext(container)
    let record = ElementRecord(
      displayName: "Manuel", canonicalName: "manuel", type: .person, aliases: ["Manolo"])
    context.insert(record)
    try context.save()

    let fetched = try #require(try context.fetch(FetchDescriptor<ElementRecord>()).first)
    #expect(fetched.aliases == ["Manolo"])
  }

  @Test func `An appearance links a memory and an element on both sides after saving`() throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let context = ModelContext(container)
    let memory = MemoryRecord(
      narrative: "Comimos en casa de mi tía.", savedAt: Date(timeIntervalSince1970: 0))
    let element = ElementRecord(displayName: "Tía Rosa", canonicalName: "tia rosa", type: .person)
    let appearance = AppearanceRecord(memory: memory, element: element, status: .confirmedByUser)
    context.insert(memory)
    context.insert(element)
    context.insert(appearance)
    try context.save()

    #expect(memory.appearances.count == 1)
    #expect(element.appearances.count == 1)
  }

  @Test func `Deleting a memory cascades and removes its appearance`() throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let context = ModelContext(container)
    let memory = MemoryRecord(
      narrative: "Un paseo por la playa.", savedAt: Date(timeIntervalSince1970: 0))
    let element = ElementRecord(
      displayName: "Playa de la Malvarrosa", canonicalName: "playa de la malvarrosa", type: .place)
    let appearance = AppearanceRecord(memory: memory, element: element, status: .proposed)
    context.insert(memory)
    context.insert(element)
    context.insert(appearance)
    try context.save()

    context.delete(memory)
    try context.save()

    let remaining = try context.fetch(FetchDescriptor<AppearanceRecord>())
    #expect(remaining.isEmpty)
  }

  @Test func `Deleting an element cascades and removes its discard`() throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let context = ModelContext(container)
    let element = ElementRecord(
      displayName: "Reloj de mi abuelo", canonicalName: "reloj de mi abuelo", type: .object)
    let discard = DiscardRecord(gapType: "unico-recuerdo", element: element)
    context.insert(element)
    context.insert(discard)
    try context.save()

    context.delete(element)
    try context.save()

    let remaining = try context.fetch(FetchDescriptor<DiscardRecord>())
    #expect(remaining.isEmpty)
  }
}
