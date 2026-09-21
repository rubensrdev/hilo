import Foundation
import SwiftData
import Testing

@testable import Hilo

// F2.2: values Sendable de ida y vuelta por el actor de modelo, sin reglas de dominio de por medio
struct PersistenceActorTests {
  static let fixedSavedAt = Date(timeIntervalSince1970: 0)

  @Test
  func `A memory saved without a date is fetched with the same id, narrative, savedAt and no date`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Aprendí a nadar en la piscina del pueblo.", savedAt: Self.fixedSavedAt))

    let savedID = try await actor.save(memory, isAnalyzed: false, isExample: false)
    #expect(savedID == memory.id)

    let fetched = try #require(try await actor.fetchMemories().first)
    #expect(fetched.id == memory.id)
    #expect(fetched.narrative == memory.narrative)
    #expect(fetched.savedAt == memory.savedAt)
    #expect(fetched.date == nil)
  }

  @Test func `A memory saved with a MemoryDate keeps its text and deduced year after fetching`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let date = try #require(MemoryDate(text: "el verano del 87", deducedYear: 1987))
    let memory = try #require(
      Memory(narrative: "Aquel verano en la playa.", date: date, savedAt: Self.fixedSavedAt))

    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)

    let fetched = try #require(try await actor.fetchMemories().first)
    #expect(fetched.date?.text == "el verano del 87")
    #expect(fetched.date?.deducedYear == 1987)
  }

  @Test
  func
    `An element saved with non-empty aliases is fetched with the same id, displayName, type and aliases`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let element = try #require(
      Element(displayName: "Manuel", type: .person, aliases: ["Manolo", "Tío Manuel"]))

    let savedID = try await actor.save(element)
    #expect(savedID == element.id)

    let fetched = try #require(try await actor.fetchElements().first)
    #expect(fetched.id == element.id)
    #expect(fetched.displayName == "Manuel")
    #expect(fetched.type == .person)
    #expect(fetched.aliases == ["Manolo", "Tío Manuel"])
  }

  @Test
  func
    `Saving an element stores its canonical name without the leading article, in the underlying record`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let element = try #require(Element(displayName: "El Abuelo", type: .person))

    _ = try await actor.save(element)

    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<ElementRecord>()).first)
    #expect(record.canonicalName == CanonicalName.of("El Abuelo"))
  }

  @Test
  func
    `An appearance connecting a saved memory and element is fetched with the same ids, role and status`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Comimos en casa de mi tía.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Tía Rosa", type: .person))
    let role = try #require(ElementRole(text: "la anfitriona"))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    let appearance = Appearance(
      memoryID: memory.id, elementID: element.id, role: role, status: .confirmedByUser)

    try await actor.save(appearance)

    let fetched = try #require(try await actor.fetchAppearances().first)
    #expect(fetched.memoryID == memory.id)
    #expect(fetched.elementID == element.id)
    #expect(fetched.role?.text == "la anfitriona")
    #expect(fetched.status == .confirmedByUser)
  }

  @Test func `Saving an appearance whose memory was never saved throws memoryNotFound`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let missingMemoryID = MemoryID()
    let element = try #require(Element(displayName: "Un banco del parque", type: .object))
    _ = try await actor.save(element)
    let appearance = Appearance(
      memoryID: missingMemoryID, elementID: element.id, role: nil, status: .proposed)

    await #expect(throws: PersistenceActor.WriteError.memoryNotFound) {
      try await actor.save(appearance)
    }
  }

  @Test func `Saving an appearance whose element was never saved throws elementNotFound`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un paseo por el parque.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    let missingElementID = ElementID()
    let appearance = Appearance(
      memoryID: memory.id, elementID: missingElementID, role: nil, status: .proposed)

    await #expect(throws: PersistenceActor.WriteError.elementNotFound) {
      try await actor.save(appearance)
    }
  }

  @Test
  func `A freshly created container returns empty arrays for memories, elements and appearances`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    #expect(try await actor.fetchMemories().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
    #expect(try await actor.fetchAppearances().isEmpty)
  }

  // contrato 3 + DEC-27: la foto se guarda como pixeles, nunca con sus metadatos de ubicacion
  @Test func `A memory saved with a photo is fetched with pixel data stripped of its GPS metadata`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Una tarde en el mirador.", savedAt: Self.fixedSavedAt))
    let originalPhoto = try PhotoStripperTests.jpegWithGPS()
    #expect(PhotoStripperTests.gpsDictionary(in: originalPhoto) != nil)

    let savedID = try await actor.save(
      memory, photoData: originalPhoto, isAnalyzed: false, isExample: false)

    let storedPhoto = try #require(try await actor.photoData(for: savedID))
    #expect(storedPhoto != originalPhoto)
    #expect(PhotoStripperTests.gpsDictionary(in: storedPhoto) == nil)
  }

  @Test func `A memory saved without a photo has no photo data when fetched`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un domingo sin cámara.", savedAt: Self.fixedSavedAt))

    let savedID = try await actor.save(memory, isAnalyzed: false, isExample: false)

    #expect(try await actor.photoData(for: savedID) == nil)
  }

  @Test func `Fetching photo data for a memory id that was never saved returns nil`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    #expect(try await actor.photoData(for: MemoryID()) == nil)
  }

  // contrato 4 + reglas 11/12: la limpieza de huerfanos ocurre en el camino de escritura
  @Test func `Deleting a memory removes an element that only appeared in it`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un paseo por el puerto con mi abuelo.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Abuelo", type: .person))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(
      Appearance(memoryID: memory.id, elementID: element.id, role: nil, status: .confirmedByUser))

    try await actor.deleteMemory(id: memory.id)

    let remainingElements = try await actor.fetchElements()
    #expect(!remainingElements.contains { $0.id == element.id })
  }

  @Test func `Deleting a memory keeps an element that still appears in another memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let firstMemory = try #require(
      Memory(narrative: "Comimos marisco en la lonja.", savedAt: Self.fixedSavedAt))
    let secondMemory = try #require(
      Memory(narrative: "Volvimos a la lonja al año siguiente.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Tío Paco", type: .person))
    _ = try await actor.save(firstMemory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(secondMemory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(
      Appearance(
        memoryID: firstMemory.id, elementID: element.id, role: nil, status: .confirmedByUser))
    try await actor.save(
      Appearance(
        memoryID: secondMemory.id, elementID: element.id, role: nil, status: .confirmedByUser))

    try await actor.deleteMemory(id: firstMemory.id)

    let remainingElements = try await actor.fetchElements()
    #expect(remainingElements.contains { $0.id == element.id })
  }

  @Test func `Deleting a memory with a photo removes its photo data`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "La última tarde en el mirador.", savedAt: Self.fixedSavedAt))
    let photo = try PhotoStripperTests.jpegWithGPS()
    let savedID = try await actor.save(
      memory, photoData: photo, isAnalyzed: false, isExample: false)

    try await actor.deleteMemory(id: savedID)

    #expect(try await actor.photoData(for: savedID) == nil)
  }

  @Test func `Deleting a memory removes its appearances`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Cena de despedida en casa de Elena.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Elena", type: .person))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(
      Appearance(memoryID: memory.id, elementID: element.id, role: nil, status: .proposed))

    try await actor.deleteMemory(id: memory.id)

    let remainingAppearances = try await actor.fetchAppearances()
    #expect(!remainingAppearances.contains { $0.memoryID == memory.id })
  }

  @Test func `Deleting a memory id that was never saved throws memoryNotFound`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    await #expect(throws: PersistenceActor.WriteError.memoryNotFound) {
      try await actor.deleteMemory(id: MemoryID())
    }
  }

  @Test func `Deleting a memory with no elements or appearances leaves it out of fetchMemories`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un día cualquiera sin nada especial.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)

    try await actor.deleteMemory(id: memory.id)

    let remainingMemories = try await actor.fetchMemories()
    #expect(!remainingMemories.contains { $0.id == memory.id })
  }

  // F2.5: memoria de ejemplo, carga, borrado e idempotencia
  @Test func `Loading the example memory in Spanish produces five memories`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    #expect(try await actor.fetchMemories().count == 5)
  }

  @Test
  func `Loading the example memory in Spanish gives José four appearances and el reloj three`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    let elements = try await actor.fetchElements()
    let appearances = try await actor.fetchAppearances()
    let jose = try #require(elements.first { $0.displayName == "José" })
    let watch = try #require(elements.first { $0.displayName == "el reloj" })
    #expect(appearances.filter { $0.elementID == jose.id }.count == 4)
    #expect(appearances.filter { $0.elementID == watch.id }.count == 3)
  }

  @Test
  func `Loading the example memory in English gives José four appearances and the watch three`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .english, loadedAt: Self.fixedSavedAt)

    let elements = try await actor.fetchElements()
    let appearances = try await actor.fetchAppearances()
    let jose = try #require(elements.first { $0.displayName == "José" })
    let watch = try #require(elements.first { $0.displayName == "the watch" })
    #expect(appearances.filter { $0.elementID == jose.id }.count == 4)
    #expect(appearances.filter { $0.elementID == watch.id }.count == 3)
  }

  @Test
  func
    `Loading the example memory saves every memory analyzed and every appearance confirmed by the user`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    let context = ModelContext(container)
    let memoryRecords = try context.fetch(FetchDescriptor<MemoryRecord>())
    #expect(memoryRecords.count == 5)
    #expect(memoryRecords.allSatisfy { $0.isAnalyzed })

    let appearances = try await actor.fetchAppearances()
    #expect(!appearances.isEmpty)
    #expect(appearances.allSatisfy { $0.status == .confirmedByUser })
  }

  @Test
  func `Loading the example memory twice does not duplicate memories, elements or appearances`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)
    let memoriesAfterFirstLoad = try await actor.fetchMemories().count
    let elementsAfterFirstLoad = try await actor.fetchElements().count
    let appearancesAfterFirstLoad = try await actor.fetchAppearances().count

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    #expect(try await actor.fetchMemories().count == memoriesAfterFirstLoad)
    #expect(try await actor.fetchElements().count == elementsAfterFirstLoad)
    #expect(try await actor.fetchAppearances().count == appearancesAfterFirstLoad)
  }

  @Test
  func
    `Loading the example memory in English after Spanish is a no-op once an example already exists`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    try await actor.loadExampleMemory(language: .english, loadedAt: Self.fixedSavedAt)

    #expect(try await actor.fetchMemories().count == 5)
    let elements = try await actor.fetchElements()
    #expect(elements.contains { $0.displayName == "el reloj" })
    #expect(!elements.contains { $0.displayName == "the watch" })
  }

  @Test func `Deleting the example memory removes its memories and leaves no elements behind`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    try await actor.deleteExampleMemory()

    #expect(try await actor.fetchMemories().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
  }

  @Test
  func
    `Deleting the example memory keeps an element that also appears in a real memory, with only that appearance left`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)
    let joseFromExample = try #require(
      try await actor.fetchElements().first { $0.displayName == "José" })
    let realMemory = try #require(
      Memory(narrative: "Comimos con José el domingo pasado.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(realMemory, isAnalyzed: false, isExample: false)
    try await actor.save(
      Appearance(
        memoryID: realMemory.id, elementID: joseFromExample.id, role: nil,
        status: .confirmedByUser))

    try await actor.deleteExampleMemory()

    let remainingElements = try await actor.fetchElements()
    #expect(remainingElements.count == 1)
    let jose = try #require(remainingElements.first { $0.displayName == "José" })
    let remainingAppearances = try await actor.fetchAppearances()
    #expect(remainingAppearances.filter { $0.elementID == jose.id }.count == 1)
  }
}
