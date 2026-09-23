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

  // el defecto de F4.5.1: la tarjeta seguia el orden de extraccion, no el de los bloques
  @Test func `beginningNames follow the block order: people, then places, then objects`() throws {
    let state = ReviewState(
      candidates: [
        try candidate("José", .person),
        try candidate("el reloj", .object),
        try candidate("la casa del pueblo", .place),
        try candidate("Carmen", .person),
      ],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])

    #expect(
      state.blocks.beginningNames == ["José", "Carmen", "la casa del pueblo", "el reloj"])
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

  @Test
  func
    `a doubtful item's candidates carry the known element's name and otherMemoriesCount, DEC-22`()
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
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: appearances, excludingMemoryID: thisMemory)

    let doubtful = try #require(state.blocks.doubtful.first)
    #expect(doubtful.candidates.count == 1)
    let onlyCandidate = try #require(doubtful.candidates.first)
    #expect(onlyCandidate.id == jose.id)
    #expect(onlyCandidate.name == jose.displayName)
    #expect(onlyCandidate.otherMemoriesCount == 2)
  }

  // DEC-50 (cierra DEC-36): la misma mencion dos veces en un recuerdo es un solo elemento, una sola fila
  @Test func `Two mentions of a known element in one memory give one known row with the first role`()
    throws
  {
    let cadiz = try #require(Element(displayName: "Cádiz", type: .place))
    let state = ReviewState(
      extracted: ExtractedMemory(
        elements: [
          ExtractedElement(name: "Cádiz", type: .place, role: "donde vivía mi tía"),
          ExtractedElement(name: "cadiz", type: .place, role: "donde aprendí a coser"),
        ],
        dateText: nil, deducedYear: nil),
      knownElements: [cadiz], appearances: [])

    #expect(state.blocks.known.map(\.name) == ["Cádiz"])
    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")
    #expect(
      outcome.confirmedAppearances == [
        .init(elementID: cadiz.id, role: ElementRole(text: "donde vivía mi tía"))
      ])
  }

  @Test func `Two mentions that raise the same identity doubt give one doubtful row with the first role`()
    throws
  {
    let singer = try #require(Element(displayName: "máquina Singer", type: .object))
    let state = ReviewState(
      extracted: ExtractedMemory(
        elements: [
          ExtractedElement(name: "Singer", type: .object, role: "la de la abuela"),
          ExtractedElement(name: "Singer", type: .object, role: "con la que cosía"),
        ],
        dateText: nil, deducedYear: nil),
      knownElements: [singer], appearances: [])

    #expect(state.blocks.doubtful.map(\.name) == ["Singer"])
    let doubt = try #require(state.blocks.doubtful.first)
    var answered = state
    answered.confirmDoubt(doubt.id, as: singer.id)
    let outcome = answered.outcome(memoryID: MemoryID(), dateTextAtSave: "")
    #expect(
      outcome.confirmedAppearances == [
        .init(elementID: singer.id, role: ElementRole(text: "la de la abuela"))
      ])
  }
  // MARK: reglas que antes vivian en la vista — nada reconocido, quitados en el bloque 1, grupos

  @Test func `Nothing recognized only when no block has content and nothing was removed`() throws {
    let empty = ReviewState(
      candidates: [], extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    var allRemoved = ReviewState(
      candidates: [try candidate("José", .person)], extractedDateText: nil,
      extractedDeducedYear: nil, knownElements: [], appearances: [])
    let jose = try #require(allRemoved.items.first).id
    allRemoved.remove(jose)

    #expect(empty.blocks.isNothingRecognized)
    #expect(!allRemoved.blocks.isNothingRecognized)
  }

  // DEC-17: lo quitado sigue en el bloque 1 para poder deshacerlo
  @Test func `A removed element stays in the understood block, marked as removed`() throws {
    var state = ReviewState(
      candidates: [try candidate("José", .person), try candidate("Cádiz", .place)],
      extractedDateText: nil, extractedDeducedYear: nil, knownElements: [], appearances: [])
    let cadiz = try #require(state.items.first { $0.originalName == "Cádiz" }).id
    state.remove(cadiz)

    let rows = state.blocks.understoodGroups.flatMap(\.rows)
    #expect(state.blocks.showsUnderstood)
    #expect(rows.map(\.name) == ["José", "Cádiz"])
    #expect(rows.map(\.isRemoved) == [false, true])
  }

  @Test func `Only removed elements still show the understood block`() throws {
    var state = ReviewState(
      candidates: [try candidate("José", .person)], extractedDateText: nil,
      extractedDeducedYear: nil, knownElements: [], appearances: [])
    state.remove(try #require(state.items.first).id)

    #expect(state.blocks.showsUnderstood)
    #expect(state.blocks.understoodGroups.map(\.type) == [.person])
  }

  @Test func `Understood groups go people, places, objects, with removed rows after active ones`()
    throws
  {
    var state = ReviewState(
      candidates: [
        try candidate("el reloj", .object),
        try candidate("Carmen", .person),
        try candidate("Cádiz", .place),
        try candidate("José", .person),
      ],
      extractedDateText: nil, extractedDeducedYear: nil, knownElements: [], appearances: [])
    let carmen = try #require(state.items.first { $0.originalName == "Carmen" }).id
    state.remove(carmen)

    let groups = state.blocks.understoodGroups
    #expect(groups.map(\.type) == [.person, .place, .object])
    #expect(groups.first?.rows.map(\.name) == ["José", "Carmen"])
  }

  @Test func `No understood block when nothing is new and nothing was removed`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let state = ReviewState(
      candidates: [try candidate("José", .person)], extractedDateText: nil,
      extractedDeducedYear: nil, knownElements: [jose], appearances: [])

    #expect(!state.blocks.showsUnderstood)
    #expect(state.blocks.understoodGroups.isEmpty)
  }
}
