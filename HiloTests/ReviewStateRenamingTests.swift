import Testing

@testable import Hilo

// contrato 4 (DEC-40, DEC-26, DEC-41): el renombrado es pendiente, y colisiona segun la categoria efectiva
nonisolated struct ReviewStateRenamingTests {
  private func candidate(_ name: String, _ type: ElementType, role: String? = nil) throws
    -> ReviewCandidate
  {
    try #require(
      ReviewCandidate(name: name, type: type, role: role.flatMap { ElementRole(text: $0) }))
  }

  @Test
  func
    `renaming la tía Carmen to Carmen is blocked, naming the element it collides with, and leaves pendingName untouched`()
    throws
  {
    // caso del spec, comportamiento linea 125
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let auntCarmen = try #require(Element(displayName: "la tía Carmen", type: .person))
    var state = ReviewState(
      candidates: [try candidate("la tía Carmen", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [carmen, auntCarmen], appearances: [])
    let itemID = try #require(state.items.first?.id)
    #expect(state.blocks.known.map(\.name) == ["la tía Carmen"])

    let outcome = state.rename(itemID, to: "Carmen")

    #expect(outcome == .blocked(carmen.id))
    #expect(state.items.first?.pendingName == nil)
    #expect(state.items.first?.currentName == "la tía Carmen")
  }

  @Test func `renaming a recognized item to a free name is applied and becomes the current name`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)

    let outcome = state.rename(itemID, to: "Pepe")

    #expect(outcome == .applied)
    #expect(state.items.first?.pendingName == "Pepe")
    #expect(state.blocks.known.map(\.name) == ["Pepe"])
  }

  @Test func `renaming a recognized item to its own current name never blocks`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)

    let outcome = state.rename(itemID, to: "José")

    #expect(outcome == .applied)
  }

  @Test
  func
    `renaming a new item to an existing canonical name turns it into a rejectable recognition, DEC-41`()
    throws
  {
    // caso del spec, comportamiento linea 126
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    var state = ReviewState(
      candidates: [try candidate("la tía", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [carmen], appearances: [])
    let itemID = try #require(state.items.first?.id)
    #expect(state.blocks.understood.map(\.name) == ["la tía"])

    let outcome = state.rename(itemID, to: "Carmen")

    #expect(outcome == .becameRecognized([carmen.id]))
    #expect(state.items.first?.identity == .recognized([carmen.id], rejected: false))
    #expect(state.items.first?.pendingName == "Carmen")
    #expect(state.blocks.understood.isEmpty)
    #expect(state.blocks.known.map(\.name) == ["Carmen"])
  }

  @Test func `renaming a new item to a name that stays unmatched simply applies the pending name`()
    throws
  {
    var state = ReviewState(
      candidates: [try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let itemID = try #require(state.items.first?.id)

    let outcome = state.rename(itemID, to: "Federico")

    #expect(outcome == .applied)
    #expect(state.items.first?.identity == .new)
    #expect(state.blocks.understood.map(\.name) == ["Federico"])
  }

  @Test
  func
    `renaming a doubtful item is always applied, without a collision check, the UI never offers renaming there`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)

    let outcome = state.rename(itemID, to: "José")

    #expect(outcome == .applied)
    #expect(state.items.first?.pendingName == "José")
  }

  @Test func `renaming a removed item is always applied, regardless of collisions`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.remove(itemID)

    let outcome = state.rename(itemID, to: "cualquier cosa")

    #expect(outcome == .applied)
    #expect(state.items.first?.pendingName == "cualquier cosa")
  }
}
