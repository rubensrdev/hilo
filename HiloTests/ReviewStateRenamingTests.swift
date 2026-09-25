import Testing

@testable import Hilo

/// Renames are pending, and collide according to the item's effective category.
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

  // A rename also collides with the other candidates in this review: what will exist on save,
  // not only what is already persisted.

  @Test
  func
    `renaming a new item to the name another candidate was extracted with is blocked, naming that sibling item`()
    throws
  {
    var state = ReviewState(
      candidates: [try candidate("Federico", .person), try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let federicoID = try #require(state.items.first(where: { $0.originalName == "Federico" })?.id)
    let manoloID = try #require(state.items.first(where: { $0.originalName == "Manolo" })?.id)

    let outcome = state.rename(federicoID, to: "Manolo")

    #expect(outcome == .blockedByReviewItem(manoloID))
    #expect(state.items.first(where: { $0.id == federicoID })?.pendingName == nil)
    #expect(state.blocks.understood.map(\.name).contains("Federico"))
  }

  @Test
  func
    `renaming a new item to a name another item was already renamed to is blocked, naming that sibling item`()
    throws
  {
    var state = ReviewState(
      candidates: [try candidate("Federico", .person), try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let federicoID = try #require(state.items.first(where: { $0.originalName == "Federico" })?.id)
    let manoloID = try #require(state.items.first(where: { $0.originalName == "Manolo" })?.id)
    #expect(state.rename(manoloID, to: "Pepito") == .applied)

    let outcome = state.rename(federicoID, to: "Pepito")

    #expect(outcome == .blockedByReviewItem(manoloID))
    #expect(state.items.first(where: { $0.id == federicoID })?.pendingName == nil)
  }

  /// Precedence guard: the check against review siblings must not break known-element collisions.
  @Test
  func
    `renaming two different new items to an existing element's name recognizes both against it instead of blocking them against each other, DEC-41 precedence`()
    throws
  {
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    var state = ReviewState(
      candidates: [try candidate("la tía", .person), try candidate("Auntie", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [carmen], appearances: [])
    let auntID = try #require(state.items.first(where: { $0.originalName == "la tía" })?.id)
    let auntieID = try #require(state.items.first(where: { $0.originalName == "Auntie" })?.id)
    #expect(state.rename(auntID, to: "Carmen") == .becameRecognized([carmen.id]))

    let outcome = state.rename(auntieID, to: "Carmen")

    #expect(outcome == .becameRecognized([carmen.id]))
  }

  @Test
  func `renaming an existing element to a new sibling's name is blocked, naming that sibling item`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person), try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let joseItemID = try #require(state.items.first(where: { $0.originalName == "José" })?.id)
    let manoloID = try #require(state.items.first(where: { $0.originalName == "Manolo" })?.id)

    let outcome = state.rename(joseItemID, to: "Manolo")

    #expect(outcome == .blockedByReviewItem(manoloID))
    #expect(state.items.first(where: { $0.id == joseItemID })?.pendingName == nil)
  }

  @Test func `renaming to a sibling's name of a different type is not blocked`() throws {
    var state = ReviewState(
      candidates: [try candidate("Manolo", .person), try candidate("Federico", .place)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let federicoID = try #require(state.items.first(where: { $0.originalName == "Federico" })?.id)

    let outcome = state.rename(federicoID, to: "Manolo")

    #expect(outcome == .applied)
    #expect(state.items.first(where: { $0.id == federicoID })?.pendingName == "Manolo")
  }

  @Test
  func
    `a removed sibling still blocks a rename toward its name, so undoing the removal never produces a duplicate`()
    throws
  {
    var state = ReviewState(
      candidates: [try candidate("Federico", .person), try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let federicoID = try #require(state.items.first(where: { $0.originalName == "Federico" })?.id)
    let manoloID = try #require(state.items.first(where: { $0.originalName == "Manolo" })?.id)
    state.remove(manoloID)

    let outcome = state.rename(federicoID, to: "Manolo")

    #expect(outcome == .blockedByReviewItem(manoloID))
  }
}
