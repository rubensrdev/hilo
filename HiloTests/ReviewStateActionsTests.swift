import Testing

@testable import Hilo

// reglas 6, 7, 9 y DEC-17: rechazar, confirmar, quitar y deshacer sobre el estado de revision
nonisolated struct ReviewStateActionsTests {
  private func candidate(_ name: String, _ type: ElementType, role: String? = nil) throws
    -> ReviewCandidate
  {
    try #require(
      ReviewCandidate(name: name, type: type, role: role.flatMap { ElementRole(text: $0) }))
  }

  @Test func `rejecting a recognition moves the item from known to understood, regla 6`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)
    #expect(state.blocks.known.map(\.name) == ["José"])

    state.rejectRecognition(itemID)

    #expect(state.blocks.known.isEmpty)
    #expect(state.blocks.understood.map(\.name) == ["José"])
  }

  @Test
  func
    `rejectRecognition only applies to an effective recognition, a doubtful item is left untouched`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)
    let identityBefore = state.items.first?.identity

    state.rejectRecognition(itemID)

    #expect(state.items.first?.identity == identityBefore)
    #expect(state.blocks.doubtful.map(\.name) == ["José García"])
  }

  @Test func `confirming a doubt with a chosen element moves the item into known, regla 7`() throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)

    state.confirmDoubt(itemID, as: jose.id)

    #expect(state.blocks.doubtful.isEmpty)
    let known = try #require(state.blocks.known.first)
    #expect(known.elementIDs == [jose.id])
  }

  @Test func `confirmDoubt has no effect on an item that was never a doubt`() throws {
    var state = ReviewState(
      candidates: [try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let itemID = try #require(state.items.first?.id)

    state.confirmDoubt(itemID, as: ElementID())

    #expect(state.items.first?.identity == .new)
    #expect(state.blocks.understood.map(\.name) == ["Manolo"])
  }

  @Test func `rejecting a doubt moves the item into understood`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)

    state.rejectDoubt(itemID)

    #expect(state.blocks.doubtful.isEmpty)
    #expect(state.blocks.understood.map(\.name) == ["José García"])
  }

  @Test func `rejectDoubt has no effect on an item that was never a doubt`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)

    state.rejectDoubt(itemID)

    #expect(state.items.first?.identity == .recognized([jose.id], rejected: false))
    #expect(state.blocks.known.map(\.name) == ["José"])
  }

  @Test
  func
    `removing an item takes it out of every block, and restoring returns exactly what it had before, DEC-17`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)
    // deja el item con un estado no trivial antes de quitarlo, para probar que nada se pierde
    state.confirmDoubt(itemID, as: jose.id)
    let identityBeforeRemoving = try #require(state.items.first?.identity)

    state.remove(itemID)
    #expect(state.blocks.known.isEmpty)
    #expect(state.blocks.understood.isEmpty)
    #expect(state.blocks.doubtful.isEmpty)
    #expect(state.items.first?.isRemoved == true)

    state.restore(itemID)
    #expect(state.items.first?.isRemoved == false)
    #expect(state.items.first?.identity == identityBeforeRemoving)
    #expect(state.blocks.known.map(\.name) == ["José García"])
  }
}
