import Testing

@testable import Hilo

// contrato 3: resolucion de un nombre — exactamente uno de tres resultados, sin efectos
nonisolated struct ElementResolutionTests {
  @Test func `mi reloj resolves as an exact match against the existing el reloj, same type`()
    throws
  {
    let clock = try #require(Element(displayName: "el reloj", type: .object))
    let result = ElementResolution.resolving(name: "mi reloj", type: .object, against: [clock])
    #expect(result == .exactMatch([clock.id]))
  }

  @Test func `an alias counts as an exact match just like the display name`() throws {
    // regla 8: cualquier alias vale como coincidencia exacta
    let jose = try #require(Element(displayName: "José", type: .person, aliases: ["Pepe"]))
    let result = ElementResolution.resolving(name: "Pepe", type: .person, against: [jose])
    #expect(result == .exactMatch([jose.id]))
  }

  @Test func `José García resolves as an identity doubt against the existing José, same type`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let result = ElementResolution.resolving(name: "José García", type: .person, against: [jose])
    #expect(result == .identityDoubt([jose.id]))
  }

  @Test
  func
    `same canonical but different type resolves as new, Granada the place does not match Granada the person`()
    throws
  {
    let placeGranada = try #require(Element(displayName: "Granada", type: .place))
    let result = ElementResolution.resolving(
      name: "Granada", type: .person, against: [placeGranada])
    #expect(result == .new)
  }

  @Test func `resolving against no elements is always new`() {
    let result = ElementResolution.resolving(name: "Carmen", type: .person, against: [])
    #expect(result == .new)
  }

  @Test func `exact match collects every element that matches, not just the first`() throws {
    let firstAna = try #require(Element(displayName: "Ana", type: .person))
    let secondAna = try #require(Element(displayName: "ANA", type: .person))
    let result = ElementResolution.resolving(
      name: "Ana", type: .person, against: [firstAna, secondAna])
    #expect(result == .exactMatch([firstAna.id, secondAna.id]))
  }

  @Test func `identity doubt collects every element that resembles, not just the first`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let joseGarciaPerez = try #require(Element(displayName: "José García Pérez", type: .person))
    let result = ElementResolution.resolving(
      name: "José García", type: .person, against: [jose, joseGarciaPerez])
    #expect(result == .identityDoubt([jose.id, joseGarciaPerez.id]))
  }

  @Test func `exact match takes priority over identity doubt from a different element`() throws {
    // contrato 3: exactamente uno de los tres resultados, la duda no contamina una coincidencia exacta ya encontrada
    let exactJoseGarcia = try #require(Element(displayName: "José García", type: .person))
    let doubtfulJose = try #require(Element(displayName: "José", type: .person))
    let result = ElementResolution.resolving(
      name: "José García", type: .person, against: [exactJoseGarcia, doubtfulJose])
    #expect(result == .exactMatch([exactJoseGarcia.id]))
  }

  @Test func `the order of the existing elements does not affect the result`() throws {
    let firstAna = try #require(Element(displayName: "Ana", type: .person))
    let secondAna = try #require(Element(displayName: "ANA", type: .person))
    let inOrder = ElementResolution.resolving(
      name: "Ana", type: .person, against: [firstAna, secondAna])
    let reversed = ElementResolution.resolving(
      name: "Ana", type: .person, against: [secondAna, firstAna])
    #expect(inOrder == reversed)
    #expect(reversed == .exactMatch([firstAna.id, secondAna.id]))
  }
}
