import Testing

@testable import Hilo

nonisolated struct ElementRenamingTests {
  @Test func `renaming to a canonical name that is free is never a collision`() throws {
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let result = NameCollision.checking(
      "Beatriz", type: .person, excluding: carmen.id, against: [carmen])
    #expect(result == .none)
  }

  @Test func `renaming an element to its own current name never self-rejects`() throws {
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let result = NameCollision.checking(
      "Carmen", type: .person, excluding: carmen.id, against: [carmen])
    #expect(result == .none)
  }

  @Test func `renaming la tía Carmen to Carmen is rejected, naming the element it collides with`()
    throws
  {
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let auntCarmen = try #require(Element(displayName: "la tía Carmen", type: .person))
    let result = NameCollision.checking(
      "Carmen", type: .person, excluding: auntCarmen.id, against: [carmen, auntCarmen])
    #expect(result == .collidesWith(carmen.id))
  }

  @Test func `renaming to a name that matches another element's alias is rejected`() throws {
    let jose = try #require(Element(displayName: "José", type: .person, aliases: ["Pepe"]))
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let result = NameCollision.checking(
      "Pepe", type: .person, excluding: carmen.id, against: [jose, carmen])
    #expect(result == .collidesWith(jose.id))
  }

  @Test
  func
    `same canonical name but different type never collides, Granada the place does not block Granada the person`()
    throws
  {
    let placeGranada = try #require(Element(displayName: "Granada", type: .place))
    let personToRename = try #require(Element(displayName: "Ana", type: .person))
    let result = NameCollision.checking(
      "Granada", type: .person, excluding: personToRename.id,
      against: [placeGranada, personToRename])
    #expect(result == .none)
  }

  @Test func `adding a new alias that collides with another element's display name is rejected`()
    throws
  {
    // Adding an alias is validated by the same function as renaming.
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let manolo = try #require(Element(displayName: "Manolo", type: .person))
    let result = NameCollision.checking(
      "Carmen", type: .person, excluding: manolo.id, against: [carmen, manolo])
    #expect(result == .collidesWith(carmen.id))
  }

  @Test func `an element appearing in four different memories affects four memories`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let memoryIDs = (0..<4).map { _ in MemoryID() }
    var appearances = memoryIDs.map {
      Appearance(memoryID: $0, elementID: jose.id, role: nil, status: .confirmedByUser)
    }
    // Noise: another element's appearance must not add to the count.
    appearances.append(
      Appearance(
        memoryID: MemoryID(), elementID: carmen.id, role: nil, status: .confirmedByUser))

    let result = ElementRenaming.affectedMemories(jose.id, appearances: appearances)
    #expect(result == 4)
  }

  @Test
  func
    `several appearances of the same element within the same memory count that memory once`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let guestRole = try #require(ElementRole(text: "invitado"))
    let memoryID = MemoryID()

    let appearances = [
      Appearance(memoryID: memoryID, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryID, elementID: jose.id, role: guestRole, status: .proposed),
    ]

    let result = ElementRenaming.affectedMemories(jose.id, appearances: appearances)
    #expect(result == 1)
  }

  @Test func `an element with no appearances affects zero memories`() throws {
    let notebook = try #require(Element(displayName: "un cuaderno", type: .object))
    let result = ElementRenaming.affectedMemories(notebook.id, appearances: [])
    #expect(result == 0)
  }
}
