import Testing

@testable import Hilo

// contrato 3 y 5 (regla 3, regla 7, DEC-22): lo que se guarda al confirmar la revision
nonisolated struct ReviewStateOutcomeTests {
  private func candidate(_ name: String, _ type: ElementType, role: String? = nil) throws
    -> ReviewCandidate
  {
    try #require(
      ReviewCandidate(name: name, type: type, role: role.flatMap { ElementRole(text: $0) }))
  }

  @Test func `a new item becomes an element to create, with its role and its current name`() throws
  {
    var state = ReviewState(
      candidates: [try candidate("Manolo", .person, role: "un amigo")],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.rename(itemID, to: "Manolo Ruiz")

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    let created = try #require(outcome.elementsToCreate.first)
    #expect(outcome.elementsToCreate.count == 1)
    #expect(created.element.displayName == "Manolo Ruiz")
    #expect(created.element.type == .person)
    #expect(created.role?.text == "un amigo")
    #expect(outcome.confirmedAppearances.isEmpty)
    #expect(outcome.aliasesToAdd.isEmpty)
    #expect(outcome.renamesToApply.isEmpty)
  }

  @Test
  func
    `a recognized item produces a confirmed appearance for each matched element, and a rename for each when it was renamed`()
    throws
  {
    let firstAna = try #require(Element(displayName: "Ana", type: .person))
    let secondAna = try #require(Element(displayName: "ANA", type: .person))
    var state = ReviewState(
      candidates: [try candidate("Ana", .person, role: "mi vecina")],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [firstAna, secondAna], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.rename(itemID, to: "Anita")

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(Set(outcome.confirmedAppearances.map(\.elementID)) == [firstAna.id, secondAna.id])
    #expect(outcome.confirmedAppearances.allSatisfy { $0.role?.text == "mi vecina" })
    #expect(Set(outcome.renamesToApply.map(\.elementID)) == [firstAna.id, secondAna.id])
    #expect(outcome.renamesToApply.allSatisfy { $0.newName == "Anita" })
    #expect(outcome.elementsToCreate.isEmpty)
  }

  @Test func `a recognized item that was never renamed produces no rename to apply`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(outcome.confirmedAppearances.map(\.elementID) == [jose.id])
    #expect(outcome.renamesToApply.isEmpty)
  }

  @Test
  func
    `a rejected recognition is saved as a new element, and the previous element is left untouched, regla 6`()
    throws
  {
    // caso del spec, comportamiento linea 123
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.rejectRecognition(itemID)

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(outcome.confirmedAppearances.isEmpty)
    #expect(outcome.renamesToApply.isEmpty)
    #expect(outcome.elementsToCreate.map(\.element.displayName) == ["José"])
  }

  @Test func `confirming a doubt whose current name already matches the element adds no alias`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person, aliases: ["Pepe"]))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.rename(itemID, to: "Pepe")
    state.confirmDoubt(itemID, as: jose.id)

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(outcome.confirmedAppearances.map(\.elementID) == [jose.id])
    #expect(outcome.aliasesToAdd.isEmpty)
    #expect(outcome.renamesToApply.map(\.elementID) == [jose.id])
  }

  @Test
  func
    `confirming a doubt adds the name used in this memory as an alias of the existing element, regla 7`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.confirmDoubt(itemID, as: jose.id)

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(outcome.confirmedAppearances.map(\.elementID) == [jose.id])
    #expect(outcome.aliasesToAdd.map(\.elementID) == [jose.id])
    #expect(outcome.aliasesToAdd.map(\.alias) == ["José García"])
    #expect(outcome.renamesToApply.isEmpty)
  }

  @Test func `a removed item contributes to none of the outcome lists, regardless of its identity`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person), try candidate("Manolo", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    for item in state.items {
      state.remove(item.id)
    }

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(outcome.elementsToCreate.isEmpty)
    #expect(outcome.confirmedAppearances.isEmpty)
    #expect(outcome.aliasesToAdd.isEmpty)
    #expect(outcome.renamesToApply.isEmpty)
  }

  @Test
  func
    `saving with an unanswered doubt still creates a separate element, leaving the identity question unresolved`()
    throws
  {
    // contrato 3: "guardar sin responder una duda deja los elementos separados" — el .doubt sin
    // responder sigue en el bloque de dudas, pero al guardar se trata como separado/nuevo
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    let state = ReviewState(
      candidates: [try candidate("José García", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose, joseGarciaPerez], appearances: [])

    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")

    #expect(outcome.elementsToCreate.map(\.element.displayName) == ["José García"])
    #expect(outcome.confirmedAppearances.isEmpty)
  }

  @Test
  func
    `rejecting a recognition discards its pending rename, and the new element keeps the originally extracted name`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    var state = ReviewState(
      candidates: [try candidate("José", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [jose], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.rename(itemID, to: "Pepe")

    state.rejectRecognition(itemID)

    #expect(state.items.first?.pendingName == nil)
    #expect(state.blocks.understood.map(\.name) == ["José"])
    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")
    #expect(outcome.elementsToCreate.map(\.element.displayName) == ["José"])
    #expect(outcome.renamesToApply.isEmpty)
  }

  @Test
  func
    `rejecting a recognition that came from DEC-41 discards the pending rename, and the resulting homonym with the existing element is not blocked`()
    throws
  {
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    var state = ReviewState(
      candidates: [try candidate("la tía", .person)],
      extractedDateText: nil, extractedDeducedYear: nil,
      knownElements: [carmen], appearances: [])
    let itemID = try #require(state.items.first?.id)
    state.rename(itemID, to: "Carmen")

    state.rejectRecognition(itemID)

    #expect(state.items.first?.pendingName == nil)
    #expect(state.blocks.understood.map(\.name) == ["la tía"])
    let outcome = state.outcome(memoryID: MemoryID(), dateTextAtSave: "")
    #expect(outcome.elementsToCreate.map(\.element.displayName) == ["la tía"])
    #expect(outcome.renamesToApply.isEmpty)
    #expect(outcome.confirmedAppearances.isEmpty)
  }

  @Test
  func
    `outcome resolves the date from the extracted text, the deduced year and the text at save time`()
    throws
  {
    let state = ReviewState(
      candidates: [],
      extractedDateText: "el verano del 87", extractedDeducedYear: 1987,
      knownElements: [], appearances: [])

    let unchanged = state.outcome(memoryID: MemoryID(), dateTextAtSave: "el verano del 87")
    #expect(unchanged.date?.text == "el verano del 87")
    #expect(unchanged.date?.deducedYear == 1987)

    let edited = state.outcome(memoryID: MemoryID(), dateTextAtSave: "el verano del 88")
    #expect(edited.date?.text == "el verano del 88")
    #expect(edited.date?.deducedYear == nil)

    let deleted = state.outcome(memoryID: MemoryID(), dateTextAtSave: "   ")
    #expect(deleted.date == nil)
  }
}
