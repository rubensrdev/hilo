import Foundation
import SwiftData
import Testing

@testable import Hilo

struct ElementDetailStateTests {
  // MARK: fixtures

  private static func memory(
    narrative: String, dateText: String? = nil, deducedYear: Int? = nil,
    savedAt: Date = Date(timeIntervalSince1970: 0)
  ) throws -> Memory {
    let date = try dateText.map { try #require(MemoryDate(text: $0, deducedYear: deducedYear)) }
    return try #require(Memory(narrative: narrative, date: date, savedAt: savedAt))
  }

  private static func element(
    name: String, type: ElementType = .person, aliases: [String] = []
  ) throws -> Element {
    try #require(Element(displayName: name, type: type, aliases: aliases))
  }

  private static func appearance(
    memoryID: MemoryID, elementID: ElementID, status: RecognitionStatus = .confirmedByUser
  ) -> Appearance {
    Appearance(memoryID: memoryID, elementID: elementID, role: nil, status: status)
  }

  private static func makeState(
    elementID: ElementID, actor: PersistenceActor,
    onMaterialChanged: @escaping () async -> Void = {}
  ) -> ElementDetailState {
    ElementDetailState(
      elementID: elementID, persistenceActor: actor, onMaterialChanged: onMaterialChanged)
  }

  // MARK: load

  @Test func `Loading a saved element fills element and leaves notFound false`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "Carmen")
    _ = try await actor.save(saved)
    let state = Self.makeState(elementID: saved.id, actor: actor)

    await state.load()

    #expect(state.element?.id == saved.id)
    #expect(state.element?.displayName == "Carmen")
    #expect(state.notFound == false)
  }

  @Test func `Loading an element id that was never saved leaves element nil and sets notFound`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let state = Self.makeState(elementID: ElementID(), actor: actor)

    await state.load()

    #expect(state.element == nil)
    #expect(state.notFound)
  }

  // MARK: ownMemories — deduced year descending, then savedAt descending, undated last

  @Test func `ownMemories follows DEC-35 order, with Memory isOrderedBefore as the oracle`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let jose = try Self.element(name: "José")
    let old = try Self.memory(
      narrative: "Cuando José era pequeño.", dateText: "cuando José era pequeño",
      deducedYear: 1975)
    let middle = try Self.memory(
      narrative: "La boda de José.", dateText: "el día de la boda", deducedYear: 1995)
    let recent = try Self.memory(
      narrative: "José, hace poco.", dateText: "el año pasado", deducedYear: 2010)
    let noYear = try Self.memory(narrative: "José, sin fecha alguna.")
    let unrelated = try Self.memory(narrative: "Un recuerdo sin José.", deducedYear: 2000)
    _ = try await actor.save(jose)
    for candidate in [old, middle, recent, noYear, unrelated] {
      _ = try await actor.save(candidate, isAnalyzed: true, isExample: false)
    }
    for own in [old, middle, recent, noYear] {
      try await actor.save(Self.appearance(memoryID: own.id, elementID: jose.id))
    }
    let state = Self.makeState(elementID: jose.id, actor: actor)

    await state.load()

    // Independent oracle: Memory.isOrderedBefore, called directly on what the actor reads.
    let allMemories = try await actor.fetchMemories()
    let ownIDs: Set<MemoryID> = [old.id, middle.id, recent.id, noYear.id]
    let expectedOrder = allMemories.filter { ownIDs.contains($0.id) }.sorted(
      by: Memory.isOrderedBefore)
    #expect(state.ownMemories.map(\.id) == expectedOrder.map(\.id))
    #expect(state.ownMemories.map(\.id) == [recent.id, middle.id, old.id, noYear.id])
  }

  @Test func `ownMemories excludes memories where the element does not appear`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let carmen = try Self.element(name: "Carmen")
    let withCarmen = try Self.memory(narrative: "Carmen en la playa.")
    let withoutCarmen = try Self.memory(narrative: "Un paseo sin Carmen.")
    _ = try await actor.save(carmen)
    _ = try await actor.save(withCarmen, isAnalyzed: true, isExample: false)
    _ = try await actor.save(withoutCarmen, isAnalyzed: true, isExample: false)
    try await actor.save(Self.appearance(memoryID: withCarmen.id, elementID: carmen.id))
    let state = Self.makeState(elementID: carmen.id, actor: actor)

    await state.load()

    #expect(state.ownMemories.map(\.id) == [withCarmen.id])
  }

  // MARK: dateRangeDisplay — the user's words at both ends, in memory order

  @Test func `dateRangeDisplay is nil for an element with no memories of its own`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let lonely = try Self.element(name: "Un elemento sin recuerdos")
    _ = try await actor.save(lonely)
    let state = Self.makeState(elementID: lonely.id, actor: actor)

    await state.load()

    #expect(state.dateRangeDisplay == nil)
  }

  @Test func `dateRangeDisplay is nil with a single own memory, even if it has date text`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let carmen = try Self.element(name: "Carmen")
    let only = try Self.memory(narrative: "Carmen, un solo recuerdo.", dateText: "ayer")
    _ = try await actor.save(carmen)
    _ = try await actor.save(only, isAnalyzed: true, isExample: false)
    try await actor.save(Self.appearance(memoryID: only.id, elementID: carmen.id))
    let state = Self.makeState(elementID: carmen.id, actor: actor)

    await state.load()

    #expect(state.dateRangeDisplay == nil)
  }

  @Test func `dateRangeDisplay joins the oldest and the newest date text with an en dash`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let jose = try Self.element(name: "José")
    let old = try Self.memory(
      narrative: "José de pequeño.", dateText: "cuando yo era niño", deducedYear: 1975)
    let middle = try Self.memory(
      narrative: "La boda de mi hermana.", dateText: "en la boda de mi hermana",
      deducedYear: 1995)
    let recent = try Self.memory(
      narrative: "El verano pasado con José.", dateText: "el verano pasado", deducedYear: 2010)
    _ = try await actor.save(jose)
    for own in [old, middle, recent] {
      _ = try await actor.save(own, isAnalyzed: true, isExample: false)
      try await actor.save(Self.appearance(memoryID: own.id, elementID: jose.id))
    }
    let state = Self.makeState(elementID: jose.id, actor: actor)

    await state.load()

    #expect(state.dateRangeDisplay == "cuando yo era niño – el verano pasado")
  }

  @Test func `dateRangeDisplay shows only the newest text when the oldest own memory has no date`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let carmen = try Self.element(name: "Carmen")
    // No date at all: no year, so it goes last, and there is no text for that end.
    let oldestWithoutDate = try Self.memory(narrative: "Carmen, no recuerdo cuándo.")
    let newest = try Self.memory(
      narrative: "Carmen, ayer mismo.", dateText: "ayer", deducedYear: 2020)
    _ = try await actor.save(carmen)
    for own in [oldestWithoutDate, newest] {
      _ = try await actor.save(own, isAnalyzed: true, isExample: false)
      try await actor.save(Self.appearance(memoryID: own.id, elementID: carmen.id))
    }
    let state = Self.makeState(elementID: carmen.id, actor: actor)

    await state.load()

    #expect(state.ownMemories.map(\.id) == [newest.id, oldestWithoutDate.id])
    #expect(state.dateRangeDisplay == "ayer")
  }

  @Test
  func `dateRangeDisplay shows only the oldest text when the newest own memory has no date`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let carmen = try Self.element(name: "Carmen")
    // Both undated: the tie breaks on savedAt descending, not on the date text.
    let recentWithoutDate = try Self.memory(
      narrative: "Carmen, ayer mismo.", savedAt: Date(timeIntervalSince1970: 200))
    let olderWithDate = try Self.memory(
      narrative: "Carmen, hace mucho.", dateText: "hace mucho tiempo",
      savedAt: Date(timeIntervalSince1970: 100))
    _ = try await actor.save(carmen)
    for own in [recentWithoutDate, olderWithDate] {
      _ = try await actor.save(own, isAnalyzed: true, isExample: false)
      try await actor.save(Self.appearance(memoryID: own.id, elementID: carmen.id))
    }
    let state = Self.makeState(elementID: carmen.id, actor: actor)

    await state.load()

    #expect(state.ownMemories.map(\.id) == [recentWithoutDate.id, olderWithDate.id])
    #expect(state.dateRangeDisplay == "hace mucho tiempo")
  }

  @Test func `dateRangeDisplay is nil when neither extreme has date text`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let carmen = try Self.element(name: "Carmen")
    let first = try Self.memory(
      narrative: "Carmen, sin fecha, la primera.", savedAt: Date(timeIntervalSince1970: 200))
    let second = try Self.memory(
      narrative: "Carmen, sin fecha, la segunda.", savedAt: Date(timeIntervalSince1970: 100))
    _ = try await actor.save(carmen)
    for own in [first, second] {
      _ = try await actor.save(own, isAnalyzed: true, isExample: false)
      try await actor.save(Self.appearance(memoryID: own.id, elementID: carmen.id))
    }
    let state = Self.makeState(elementID: carmen.id, actor: actor)

    await state.load()

    #expect(state.dateRangeDisplay == nil)
  }

  // MARK: rename — collides when the canonical name belongs to another element of the same type

  @Test func `Renaming without a collision changes the name and reports the change`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "Jose")
    _ = try await actor.save(saved)
    var changedCount = 0
    let state = Self.makeState(elementID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.rename(to: "José")
    await state.load()

    #expect(outcome == .applied)
    #expect(state.element?.displayName == "José")
    #expect(changedCount == 1)
  }

  @Test func `Renaming trims surrounding whitespace before comparing and saving`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "Carmen")
    _ = try await actor.save(saved)
    let state = Self.makeState(elementID: saved.id, actor: actor)
    await state.load()

    let outcome = await state.rename(to: "   Carmen Ruiz   ")
    await state.load()

    #expect(outcome == .applied)
    #expect(state.element?.displayName == "Carmen Ruiz")
  }

  @Test
  func
    `Renaming to a name that collides with another element of the same type is blocked and leaves the name unchanged`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let juan = try Self.element(name: "Juan", type: .person)
    let target = try Self.element(name: "Pedro", type: .person)
    _ = try await actor.save(juan)
    _ = try await actor.save(target)
    var changedCount = 0
    let state = Self.makeState(elementID: target.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.rename(to: "juan")
    await state.load()

    #expect(outcome == .blocked(conflictName: "Juan"))
    #expect(state.element?.displayName == "Pedro")
    #expect(changedCount == 0)
  }

  @Test
  func `Renaming does not collide with an element of a different type sharing the same canonical`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let house = try Self.element(name: "Casa", type: .place)
    let target = try Self.element(name: "Pedro", type: .person)
    _ = try await actor.save(house)
    _ = try await actor.save(target)
    let state = Self.makeState(elementID: target.id, actor: actor)
    await state.load()

    let outcome = await state.rename(to: "Casa")
    await state.load()

    #expect(outcome == .applied)
    #expect(state.element?.displayName == "Casa")
  }

  @Test func `Renaming to an empty or whitespace-only name writes nothing and reports no change`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "Carmen")
    _ = try await actor.save(saved)
    var changedCount = 0
    let state = Self.makeState(elementID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.rename(to: "   ")
    await state.load()

    #expect(outcome == .failed)
    #expect(state.element?.displayName == "Carmen")
    #expect(changedCount == 0)
  }

  // MARK: addAlias — the same collision checks as rename

  @Test func `Adding an alias without a collision stores it and reports the change`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "José")
    _ = try await actor.save(saved)
    var changedCount = 0
    let state = Self.makeState(elementID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.addAlias("Pepe")
    await state.load()

    #expect(outcome == .applied)
    #expect(state.element?.aliases == ["Pepe"])
    #expect(changedCount == 1)
  }

  @Test func `Adding an alias that collides with another element of the same type is blocked`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let juan = try Self.element(name: "Juan", type: .person)
    let target = try Self.element(name: "Pedro", type: .person)
    _ = try await actor.save(juan)
    _ = try await actor.save(target)
    var changedCount = 0
    let state = Self.makeState(elementID: target.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.addAlias("juan")
    await state.load()

    #expect(outcome == .blocked(conflictName: "Juan"))
    #expect(state.element?.aliases.isEmpty == true)
    #expect(changedCount == 0)
  }

  @Test
  func
    `Adding an alias whose canonical matches the element's own name is a silent success that adds nothing`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "José")
    _ = try await actor.save(saved)
    var changedCount = 0
    let state = Self.makeState(elementID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.addAlias("josé")
    await state.load()

    #expect(outcome == .applied)
    #expect(state.element?.aliases.isEmpty == true)
    #expect(changedCount == 0)
  }

  @Test
  func
    `Adding an alias whose canonical matches an alias the element already has is a silent success`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "José", aliases: ["Pepe"])
    _ = try await actor.save(saved)
    var changedCount = 0
    let state = Self.makeState(elementID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.addAlias("PEPE")
    await state.load()

    #expect(outcome == .applied)
    #expect(state.element?.aliases == ["Pepe"])
    #expect(changedCount == 0)
  }

  @Test func `Adding an empty or whitespace-only alias writes nothing and reports no change`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let saved = try Self.element(name: "José")
    _ = try await actor.save(saved)
    var changedCount = 0
    let state = Self.makeState(elementID: saved.id, actor: actor) { changedCount += 1 }
    await state.load()

    let outcome = await state.addAlias("   ")
    await state.load()

    #expect(outcome == .failed)
    #expect(state.element?.aliases.isEmpty == true)
    #expect(changedCount == 0)
  }
}
