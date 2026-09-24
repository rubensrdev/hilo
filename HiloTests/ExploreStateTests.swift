import Foundation
import SwiftData
import Testing

@testable import Hilo

// contratos 1-4 (S1 Memoria): ExploreState gobierna las dos vistas y los cuatro estados de recuerdos
struct ExploreStateTests {
  private static let defaultExtractLength = 160

  // MARK: fixtures

  private static func memory(
    narrative: String, deducedYear: Int? = nil, savedAt: Date = Date(timeIntervalSince1970: 0)
  ) throws -> Memory {
    let date = deducedYear.flatMap { MemoryDate(text: "un año cualquiera", deducedYear: $0) }
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

  private static func makeState() throws -> (ExploreState, PersistenceActor) {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let state = ExploreState(
      persistenceActor: actor, comprehender: FakeMemoryComprehender(script: .fails(.noResponse)),
      interfaceLanguage: "es", defaultExtractLength: Self.defaultExtractLength)
    return (state, actor)
  }

  // MARK: load

  @Test
  func `Loading reads back exactly the memories, elements and appearances that were seeded`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let first = try Self.memory(narrative: "Un paseo por la feria.", deducedYear: 1990)
    let second = try Self.memory(narrative: "La comida del domingo.")
    let jose = try Self.element(name: "José")
    _ = try await actor.save(first, isAnalyzed: true, isExample: false)
    _ = try await actor.save(second, isAnalyzed: true, isExample: false)
    _ = try await actor.save(jose)
    try await actor.save(Self.appearance(memoryID: first.id, elementID: jose.id))

    await state.load()

    #expect(Set(state.memories.map(\.id)) == Set([first.id, second.id]))
    #expect(state.elements.map(\.id) == [jose.id])
    #expect(state.appearances.count == 1)
    #expect(state.appearances.first?.memoryID == first.id)
    #expect(state.appearances.first?.elementID == jose.id)
  }

  // MARK: memoriesDisplay — vacio, un recuerdo, normal

  @Test func `Zero memories with a blank query produce the empty display`() async throws {
    let (state, _) = try Self.makeState()

    await state.load()

    #expect(state.memoriesDisplay == .empty)
  }

  @Test
  func `Exactly one memory with a blank query produces the single display with that memory`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let onlyMemory = try Self.memory(narrative: "El único recuerdo guardado.")
    _ = try await actor.save(onlyMemory, isAnalyzed: true, isExample: false)

    await state.load()

    #expect(state.memoriesDisplay == .single(onlyMemory))
  }

  @Test
  func
    `Two or more memories with a blank query produce the normal display, grouped like MemoryGrouping`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let older = try Self.memory(narrative: "Un recuerdo antiguo.", deducedYear: 1975)
    let newer = try Self.memory(narrative: "Un recuerdo reciente.", deducedYear: 2015)
    _ = try await actor.save(older, isAnalyzed: true, isExample: false)
    _ = try await actor.save(newer, isAnalyzed: true, isExample: false)

    await state.load()

    guard case .normal(let groups) = state.memoriesDisplay else {
      Issue.record("expected .normal, got \(state.memoriesDisplay)")
      return
    }
    // oraculo independiente: la misma agrupacion, llamada directamente sobre lo cargado
    #expect(groups == MemoryGrouping.grouped(state.memories))
  }

  // MARK: memoriesDisplay — buscando manda siempre sobre el recuento

  @Test(arguments: [0, 1, 3])
  func `A non-blank search query always yields searching, never empty, single or normal`(
    memoryCount: Int
  ) async throws {
    let (state, actor) = try Self.makeState()
    for index in 0..<memoryCount {
      let memory = try Self.memory(narrative: "Un recuerdo cualquiera número \(index).")
      _ = try await actor.save(memory, isAnalyzed: true, isExample: false)
    }
    await state.load()

    state.searchQuery = "recuerdo"

    guard case .searching(let results) = state.memoriesDisplay else {
      Issue.record(
        "expected .searching regardless of memory count, got \(state.memoriesDisplay)")
      return
    }
    let expected = MemorySearch.results(
      for: "recuerdo", in: state.memories, elements: state.elements,
      appearances: state.appearances, defaultExtractLength: Self.defaultExtractLength)
    #expect(results == expected)
  }

  @Test
  func
    `A search query that matches nothing produces searching with empty results, not the first-run empty state`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let memory = try Self.memory(narrative: "Una tarde tranquila sin nada especial.")
    _ = try await actor.save(memory, isAnalyzed: true, isExample: false)
    await state.load()

    state.searchQuery = "reloj"

    guard case .searching(let results) = state.memoriesDisplay else {
      Issue.record(
        "expected .searching, never .empty, even with nothing to show, got \(state.memoriesDisplay)"
      )
      return
    }
    #expect(results.isEmpty)
  }

  // MARK: isSearching

  @Test(arguments: ["", "   ", "\n\t"])
  func `isSearching is false for a blank query`(query: String) throws {
    let (state, _) = try Self.makeState()
    state.searchQuery = query

    #expect(state.isSearching == false)
  }

  @Test func `isSearching is true once the query has non-blank content`() throws {
    let (state, _) = try Self.makeState()
    state.searchQuery = "reloj"

    #expect(state.isSearching)
  }

  // MARK: filteredElements

  @Test
  func
    `With no filter, filteredElements returns all elements sorted alphabetically by displayName`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let names = ["Zaida", "Ana", "Marta", "Carlos"]
    for name in names {
      _ = try await actor.save(try Self.element(name: name))
    }
    await state.load()

    state.selectedElementTypeFilter = nil

    // oraculo independiente: el mismo criterio aplicado desde cero a la entrada revuelta
    let expectedOrder = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    #expect(state.filteredElements.map(\.displayName) == expectedOrder)
  }

  @Test func `With a type filter, only elements of that type are kept, same alphabetical order`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let jose = try Self.element(name: "José", type: .person)
    let carmen = try Self.element(name: "Carmen", type: .person)
    let granada = try Self.element(name: "Granada", type: .place)
    for element in [jose, carmen, granada] {
      _ = try await actor.save(element)
    }
    await state.load()

    state.selectedElementTypeFilter = .person

    #expect(state.filteredElements.map(\.displayName) == ["Carmen", "José"])
  }

  @Test func `A filter for a type present in no seeded element produces an empty list`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    _ = try await actor.save(try Self.element(name: "José", type: .person))
    await state.load()

    state.selectedElementTypeFilter = .object

    #expect(state.filteredElements == [])
  }

  // MARK: memoryCount(for:)

  @Test
  func
    `memoryCount matches ElementMemories.count for zero, one and several memories, deduplicated`()
    async throws
  {
    let (state, actor) = try Self.makeState()
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    _ = try await actor.save(jose)
    _ = try await actor.save(carmen)
    let first = try Self.memory(narrative: "Primero, con José.")
    let second = try Self.memory(narrative: "Segundo, con José.")
    _ = try await actor.save(first, isAnalyzed: true, isExample: false)
    _ = try await actor.save(second, isAnalyzed: true, isExample: false)
    // dos apariciones de José en el mismo recuerdo (dos roles) cuentan una sola vez
    try await actor.save(
      Self.appearance(memoryID: first.id, elementID: jose.id, status: .confirmedByUser))
    try await actor.save(
      Self.appearance(memoryID: first.id, elementID: jose.id, status: .proposed))
    try await actor.save(Self.appearance(memoryID: second.id, elementID: jose.id))

    await state.load()

    #expect(
      state.memoryCount(for: carmen) == ElementMemories.count(for: carmen.id, in: state.appearances)
    )
    #expect(state.memoryCount(for: carmen) == 0)
    #expect(
      state.memoryCount(for: jose) == ElementMemories.count(for: jose.id, in: state.appearances))
    #expect(state.memoryCount(for: jose) == 2)
  }

  // MARK: loadExampleMemory

  @Test func `Loading the example memory on an empty store writes it and refreshes load's data`()
    async throws
  {
    let (state, actor) = try Self.makeState()

    await state.loadExampleMemory(language: .spanish)

    #expect(!state.memories.isEmpty)
    #expect(!state.elements.isEmpty)
    // oraculo independiente: lo que el propio actor dice que hay guardado tras la escritura
    let directMemories = try await actor.fetchMemories()
    let directElements = try await actor.fetchElements()
    #expect(Set(state.memories.map(\.id)) == Set(directMemories.map(\.id)))
    #expect(Set(state.elements.map(\.id)) == Set(directElements.map(\.id)))
  }
}
