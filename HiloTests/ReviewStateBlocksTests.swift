import Testing

@testable import Hilo

// contrato 2 + §9.2: los cuatro bloques de la revision, cada uno solo si tiene contenido
nonisolated struct ReviewStateBlocksTests {
  private func candidate(_ name: String, _ type: ElementType, role: String? = nil) throws
    -> ReviewCandidate
  {
    try #require(
      ReviewCandidate(name: name, type: type, role: role.flatMap { ElementRole(text: $0) }))
  }

  @Test
  func
    `new, recognized and unresolved-doubt candidates land in understood, known and doubtful respectively`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))

    let state = ReviewState(
      candidates: [
        try candidate("Manolo", .person),
        try candidate("José", .person),
        try candidate("José García", .person),
      ],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])

    #expect(state.blocks.understood.map(\.name) == ["Manolo"])
    #expect(state.blocks.known.map(\.name) == ["José"])
    #expect(state.blocks.doubtful.map(\.name) == ["José García"])
  }

  @Test func `isBeginning is true when something was understood but nothing is known yet`() throws {
    let state = ReviewState(
      candidates: [try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])

    #expect(state.blocks.isBeginning)
  }

  @Test func `isBeginning is false as soon as something is known`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let state = ReviewState(
      candidates: [try candidate("José", .person), try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])

    #expect(!state.blocks.isBeginning)
  }

  @Test func `isBeginning is false when nothing at all was understood`() throws {
    let state = ReviewState(
      candidates: [],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])

    #expect(state.blocks.understood.isEmpty)
    #expect(state.blocks.known.isEmpty)
    #expect(state.blocks.doubtful.isEmpty)
    #expect(!state.blocks.isBeginning)
  }

  @Test
  func
    `otherMemoriesCount counts distinct memories holding the element, excluding the one being reviewed, DEC-22`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let thisMemory = MemoryID()
    let otherMemoryA = MemoryID()
    let otherMemoryB = MemoryID()
    let appearances = [
      Appearance(memoryID: thisMemory, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: otherMemoryA, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: otherMemoryB, elementID: jose.id, role: nil, status: .proposed),
    ]

    let state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: appearances, excludingMemoryID: thisMemory)

    let known = try #require(state.blocks.known.first)
    #expect(known.otherMemoriesCount == 2)
  }

  @Test
  func
    `otherMemoriesCount for an ambiguous exact match counts memories across every matched element`()
    throws
  {
    let firstAna = try #require(Element(displayName: "Ana", type: .person))
    let secondAna = try #require(Element(displayName: "ANA", type: .person))
    let thisMemory = MemoryID()
    let memoryWithFirst = MemoryID()
    let memoryWithSecond = MemoryID()
    let appearances = [
      Appearance(
        memoryID: thisMemory, elementID: firstAna.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryWithFirst, elementID: firstAna.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryWithSecond, elementID: secondAna.id, role: nil, status: .confirmedByUser),
    ]

    let state = ReviewState(
      candidates: [try candidate("Ana", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [firstAna, secondAna], appearances: appearances,
      excludingMemoryID: thisMemory)

    let known = try #require(state.blocks.known.first)
    #expect(known.elementIDs == [firstAna.id, secondAna.id])
    #expect(known.otherMemoriesCount == 2)
  }
}
