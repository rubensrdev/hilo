import Foundation
import SwiftData
import Testing

@testable import Hilo

// S4 Detalle de recuerdo (F5.3): foto, relato, elementos propios, conexiones con motivo,
// editar (DEC-19: no reanaliza) y borrar (DEC-24: el impacto se calcula)
struct MemoryDetailStateTests {
  // MARK: fixtures

  private static func memory(
    narrative: String, deducedYear: Int? = nil, savedAt: Date = Date(timeIntervalSince1970: 0)
  ) throws -> Memory {
    let date = deducedYear.flatMap { MemoryDate(text: "un año cualquiera", deducedYear: $0) }
    return try #require(Memory(narrative: narrative, date: date, savedAt: savedAt))
  }

  private static func element(name: String, type: ElementType = .person) throws -> Element {
    try #require(Element(displayName: name, type: type))
  }

  private static func appearance(
    memoryID: MemoryID, elementID: ElementID, status: RecognitionStatus = .confirmedByUser
  ) -> Appearance {
    Appearance(memoryID: memoryID, elementID: elementID, role: nil, status: status)
  }

  private static func makeState(
    memoryID: MemoryID, actor: PersistenceActor,
    onMaterialChanged: @escaping () async -> Void = {}
  ) -> MemoryDetailState {
    MemoryDetailState(
      memoryID: memoryID, persistenceActor: actor,
      comprehender: FakeMemoryComprehender(script: .fails(.noResponse)),
      interfaceLanguage: "es", onMaterialChanged: onMaterialChanged)
  }

  // MARK: load — memoria, foto, elementos propios, conexiones, analizado

  @Test func `Loading a saved memory with a photo fills memory, photo and the analyzed flag`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Un paseo por el puerto con mi abuelo.")
    let photo = try PhotoStripperTests.jpegWithGPS()
    _ = try await actor.save(saved, photoData: photo, isAnalyzed: true, isExample: false)
    let state = Self.makeState(memoryID: saved.id, actor: actor)

    await state.load()

    #expect(state.memory?.id == saved.id)
    #expect(state.memory?.narrative == saved.narrative)
    #expect(state.photoData != nil)
    #expect(state.isAnalyzed)
    #expect(state.notFound == false)
  }

  @Test func `Loading a saved memory without a photo leaves photoData nil`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "La comida del domingo, sin foto.")
    _ = try await actor.save(saved, isAnalyzed: false, isExample: false)
    let state = Self.makeState(memoryID: saved.id, actor: actor)

    await state.load()

    #expect(state.photoData == nil)
    #expect(state.isAnalyzed == false)
  }

  @Test func `Loading fills ownElements with the memory's own elements, in order of appearance`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "José y Carmen fueron con el reloj al pueblo.")
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    let clock = try Self.element(name: "el reloj", type: .object)
    _ = try await actor.save(saved, isAnalyzed: true, isExample: false)
    for candidate in [jose, carmen, clock] { _ = try await actor.save(candidate) }
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: jose.id))
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: carmen.id))
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: clock.id))
    let state = Self.makeState(memoryID: saved.id, actor: actor)

    await state.load()

    // oraculo independiente: MemoryElements, llamado directamente sobre lo leido del actor
    let appearances = try await actor.fetchAppearances()
    let expectedOrder = MemoryElements.elementIDs(for: saved.id, in: appearances)
    #expect(state.ownElements.map(\.id) == expectedOrder)
    #expect(state.ownElements.map(\.id) == [jose.id, carmen.id, clock.id])
  }

  // dos apariciones del mismo elemento en el mismo recuerdo cuentan una sola vez
  @Test func `A memory with no recognized elements leaves ownElements and connectedRows empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Una tarde tranquila sin nada especial.")
    _ = try await actor.save(saved, isAnalyzed: true, isExample: false)
    let state = Self.makeState(memoryID: saved.id, actor: actor)

    await state.load()

    #expect(state.ownElements.isEmpty)
    #expect(state.connectedRows.isEmpty)
  }

  @Test func `A memory whose elements appear nowhere else leaves connectedRows empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Un rato leyendo con el reloj de pared.")
    let clock = try Self.element(name: "el reloj de pared", type: .object)
    _ = try await actor.save(saved, isAnalyzed: true, isExample: false)
    _ = try await actor.save(clock)
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: clock.id))
    let state = Self.makeState(memoryID: saved.id, actor: actor)

    await state.load()

    #expect(state.ownElements.map(\.id) == [clock.id])
    #expect(state.connectedRows.isEmpty)
  }

  // caso del spec, contrato 4: un recuerdo que comparte José y Granada aparece una vez, con ambos motivos
  @Test func `Two memories sharing an element connect, and the shared row lists the motive`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let origin = try Self.memory(narrative: "Un domingo de domino con José.")
    let other = try Self.memory(narrative: "José trajo naranjas del huerto.")
    let jose = try Self.element(name: "José")
    _ = try await actor.save(origin, isAnalyzed: true, isExample: false)
    _ = try await actor.save(other, isAnalyzed: true, isExample: false)
    _ = try await actor.save(jose)
    try await actor.save(Self.appearance(memoryID: origin.id, elementID: jose.id))
    try await actor.save(Self.appearance(memoryID: other.id, elementID: jose.id))
    let state = Self.makeState(memoryID: origin.id, actor: actor)

    await state.load()

    #expect(state.connectedRows.count == 1)
    #expect(state.connectedRows.first?.memoryID == other.id)
    #expect(state.connectedRows.first?.motiveNames == ["José"])
  }

  @Test func `Loading a memory id that was never saved leaves memory nil and sets notFound`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let state = Self.makeState(memoryID: MemoryID(), actor: actor)

    await state.load()

    #expect(state.memory == nil)
    #expect(state.notFound)
  }

  // MARK: deleteImpact — DEC-24, regla 11: un elemento que se quede sin recuerdos desaparece

  @Test func `deleteImpact separates an element that survives elsewhere from one that disappears`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let target = try Self.memory(narrative: "José y Carmen en la merienda.")
    let other = try Self.memory(narrative: "José, otra vez, en la playa.")
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    _ = try await actor.save(target, isAnalyzed: true, isExample: false)
    _ = try await actor.save(other, isAnalyzed: true, isExample: false)
    _ = try await actor.save(jose)
    _ = try await actor.save(carmen)
    try await actor.save(Self.appearance(memoryID: target.id, elementID: jose.id))
    try await actor.save(Self.appearance(memoryID: target.id, elementID: carmen.id))
    try await actor.save(Self.appearance(memoryID: other.id, elementID: jose.id))
    let state = Self.makeState(memoryID: target.id, actor: actor)

    await state.load()

    #expect(state.deleteImpact.surviving.map(\.id) == [jose.id])
    #expect(state.deleteImpact.disappearing.map(\.id) == [carmen.id])
  }

  @Test func `deleteImpact when every element survives elsewhere leaves disappearing empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let target = try Self.memory(narrative: "José en el mercado.")
    let other = try Self.memory(narrative: "José otra vez en el mercado.")
    let jose = try Self.element(name: "José")
    _ = try await actor.save(target, isAnalyzed: true, isExample: false)
    _ = try await actor.save(other, isAnalyzed: true, isExample: false)
    _ = try await actor.save(jose)
    try await actor.save(Self.appearance(memoryID: target.id, elementID: jose.id))
    try await actor.save(Self.appearance(memoryID: other.id, elementID: jose.id))
    let state = Self.makeState(memoryID: target.id, actor: actor)

    await state.load()

    #expect(state.deleteImpact.surviving.map(\.id) == [jose.id])
    #expect(state.deleteImpact.disappearing.isEmpty)
  }

  @Test func `deleteImpact when no element survives elsewhere leaves surviving empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let target = try Self.memory(narrative: "José, solo esta vez, en la fiesta.")
    let jose = try Self.element(name: "José")
    _ = try await actor.save(target, isAnalyzed: true, isExample: false)
    _ = try await actor.save(jose)
    try await actor.save(Self.appearance(memoryID: target.id, elementID: jose.id))
    let state = Self.makeState(memoryID: target.id, actor: actor)

    await state.load()

    #expect(state.deleteImpact.surviving.isEmpty)
    #expect(state.deleteImpact.disappearing.map(\.id) == [jose.id])
  }

  @Test func `deleteImpact for a memory with no elements is empty on both sides`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let target = try Self.memory(narrative: "Un día cualquiera sin nadie reconocido.")
    _ = try await actor.save(target, isAnalyzed: true, isExample: false)
    let state = Self.makeState(memoryID: target.id, actor: actor)

    await state.load()

    #expect(state.deleteImpact.surviving.isEmpty)
    #expect(state.deleteImpact.disappearing.isEmpty)
  }

  // MARK: editNarrative — DEC-19: editar no reanaliza

  @Test func `Editing the narrative updates what a later load returns`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "El texto original.")
    _ = try await actor.save(saved, isAnalyzed: false, isExample: false)
    let state = Self.makeState(memoryID: saved.id, actor: actor)
    await state.load()

    let success = await state.editNarrative("El texto corregido a mano.")
    await state.load()

    #expect(success)
    #expect(state.memory?.narrative == "El texto corregido a mano.")
  }

  @Test
  func
    `Editing the narrative never changes isAnalyzed nor the memory's existing elements`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "José en la feria.")
    let jose = try Self.element(name: "José")
    _ = try await actor.save(saved, isAnalyzed: true, isExample: false)
    _ = try await actor.save(jose)
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: jose.id))
    let state = Self.makeState(memoryID: saved.id, actor: actor)
    await state.load()
    let elementsBefore = state.ownElements.map(\.id)

    _ = await state.editNarrative("José en la feria, con más detalle.")
    await state.load()

    #expect(state.isAnalyzed)
    #expect(state.ownElements.map(\.id) == elementsBefore)
  }

  @Test func `A successful edit reports the material changed`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Un relato cualquiera.")
    _ = try await actor.save(saved, isAnalyzed: false, isExample: false)
    var changedCount = 0
    let state = Self.makeState(memoryID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    _ = await state.editNarrative("Un relato corregido.")

    #expect(changedCount == 1)
  }

  @Test
  func
    `Editing the narrative of a memory that no longer exists fails and never reports a change`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var changedCount = 0
    let state = Self.makeState(memoryID: MemoryID(), actor: actor) { changedCount += 1 }

    let success = await state.editNarrative("Un texto que no tiene donde guardarse.")

    #expect(success == false)
    #expect(changedCount == 0)
  }

  // MARK: delete — contrato 4, regla 12: borrar un recuerdo no borra sus elementos, salvo huerfanos

  @Test func `Deleting removes the memory from the store and reports the change`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Un recuerdo que se va a borrar.")
    _ = try await actor.save(saved, isAnalyzed: false, isExample: false)
    var changedCount = 0
    let state = Self.makeState(memoryID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let success = await state.delete()

    #expect(success)
    #expect(changedCount == 1)
    let remaining = try await actor.fetchMemories()
    #expect(!remaining.contains { $0.id == saved.id })
  }

  @Test func `Deleting a memory whose only element has no other appearances removes that element`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Un paseo con el abuelo, sin nadie más.")
    let grandfather = try Self.element(name: "Abuelo")
    _ = try await actor.save(saved, isAnalyzed: true, isExample: false)
    _ = try await actor.save(grandfather)
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: grandfather.id))
    let state = Self.makeState(memoryID: saved.id, actor: actor)
    await state.load()

    _ = await state.delete()

    let remainingElements = try await actor.fetchElements()
    #expect(!remainingElements.contains { $0.id == grandfather.id })
  }

  @Test func `Deleting a memory keeps an element that still appears in another memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.memory(narrative: "Comimos marisco en la lonja.")
    let other = try Self.memory(narrative: "Volvimos a la lonja al año siguiente.")
    let element = try Self.element(name: "Tío Paco")
    _ = try await actor.save(saved, isAnalyzed: true, isExample: false)
    _ = try await actor.save(other, isAnalyzed: true, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(Self.appearance(memoryID: saved.id, elementID: element.id))
    try await actor.save(Self.appearance(memoryID: other.id, elementID: element.id))
    let state = Self.makeState(memoryID: saved.id, actor: actor)
    await state.load()

    _ = await state.delete()

    let remainingElements = try await actor.fetchElements()
    #expect(remainingElements.contains { $0.id == element.id })
  }

  @Test
  func `Deleting a memory id that no longer exists fails and never reports a change`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var changedCount = 0
    let state = Self.makeState(memoryID: MemoryID(), actor: actor) { changedCount += 1 }

    let success = await state.delete()

    #expect(success == false)
    #expect(changedCount == 0)
  }

  // MARK: understandLater / reviewCoordinator — DEC-16, propios de cada detalle, no compartidos

  @Test func `Each detail state owns its own understandLater and reviewCoordinator instances`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let first = Self.makeState(memoryID: MemoryID(), actor: actor)
    let second = Self.makeState(memoryID: MemoryID(), actor: actor)

    #expect(first.understandLater !== second.understandLater)
    #expect(first.reviewCoordinator !== second.reviewCoordinator)
  }
}
