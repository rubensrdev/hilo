import Foundation
import Testing

@testable import Hilo

nonisolated struct MemoryConnectionsTests {
  @Test func `two memories that share José connect, with José as the only motive`() throws {
    let memoryA = try #require(Memory(narrative: "Una tarde de domino con José.", savedAt: Date()))
    let memoryB = try #require(
      Memory(narrative: "José trajo naranjas del huerto.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: jose.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(result == [MemoryConnection(memoryID: memoryB.id, motives: [jose.id])])
  }

  @Test
  func
    `a memory sharing José and Granada with another appears once, with both as motives`()
    throws
  {
    // Two shared motives, one connection.
    let memoryA = try #require(
      Memory(narrative: "Un viaje a Granada con José.", savedAt: Date()))
    let memoryB = try #require(
      Memory(narrative: "José me enseñó fotos de Granada.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))
    let granada = try #require(Element(displayName: "Granada", type: .place))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryA.id, elementID: granada.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryB.id, elementID: granada.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: jose.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(
      result == [MemoryConnection(memoryID: memoryB.id, motives: [jose.id, granada.id])])
  }

  @Test func `a third memory that shares nothing never appears in the result`() throws {
    let memoryA = try #require(Memory(narrative: "Un domingo con José.", savedAt: Date()))
    let memoryB = try #require(Memory(narrative: "José me visitó.", savedAt: Date()))
    let memoryC = try #require(Memory(narrative: "Una tarde con Carmen.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))
    let carmen = try #require(Element(displayName: "Carmen", type: .person))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryC.id, elementID: carmen.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(result == [MemoryConnection(memoryID: memoryB.id, motives: [jose.id])])
    #expect(!result.contains { $0.memoryID == memoryC.id })
  }

  @Test func `the origin memory never connects to itself even with several of its own appearances`()
    throws
  {
    let memoryA = try #require(Memory(narrative: "Un viaje con José y Granada.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))
    let granada = try #require(Element(displayName: "Granada", type: .place))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryA.id, elementID: granada.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(result.isEmpty)
  }

  @Test func `no shared elements with anyone else produces an empty list`() throws {
    let memoryA = try #require(
      Memory(narrative: "Un rato leyendo con el reloj de pared.", savedAt: Date()))
    let memoryB = try #require(Memory(narrative: "Una comida con Carmen.", savedAt: Date()))
    let clock = try #require(Element(displayName: "el reloj de pared", type: .object))
    let carmen = try #require(Element(displayName: "Carmen", type: .person))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: clock.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: carmen.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(result.isEmpty)
  }

  @Test func `an empty appearances array produces an empty list, empty is not an error`() throws {
    let memoryA = try #require(
      Memory(narrative: "Un recuerdo sin apariciones aún.", savedAt: Date()))

    let result = MemoryConnections.connected(to: memoryA, appearances: [])
    #expect(result.isEmpty)
  }

  @Test
  func
    `connections are ordered by the position of each connected memory's first qualifying appearance`()
    throws
  {
    // Stable order: by the first appearance of each distinct memory among those sharing an element
    // with the origin.
    let memoryOrigin = try #require(
      Memory(narrative: "Una tarde en el mercado, con el reloj en el bolsillo.", savedAt: Date()))
    let memoryB = try #require(Memory(narrative: "Recuperé el reloj perdido.", savedAt: Date()))
    let memoryC = try #require(Memory(narrative: "Volví al mercado de siempre.", savedAt: Date()))
    let clock = try #require(Element(displayName: "el reloj", type: .object))
    let market = try #require(Element(displayName: "el mercado", type: .place))

    let appearances = [
      Appearance(
        memoryID: memoryOrigin.id, elementID: clock.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryOrigin.id, elementID: market.id, role: nil, status: .confirmedByUser),
      // memoryC shares "mercado" and comes first in the array...
      Appearance(memoryID: memoryC.id, elementID: market.id, role: nil, status: .confirmedByUser),
      // ...memoryB shares "reloj" but comes later, even though memoryB was created before memoryC.
      Appearance(memoryID: memoryB.id, elementID: clock.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryOrigin, appearances: appearances)
    #expect(
      result == [
        MemoryConnection(memoryID: memoryC.id, motives: [market.id]),
        MemoryConnection(memoryID: memoryB.id, motives: [clock.id]),
      ])
  }

  @Test
  func
    `motives follow the order of the origin memory's own appearances, not the connected memory's order`()
    throws
  {
    // Motive order comes from the origin memory, never from the connected one.
    let memoryOrigin = try #require(
      Memory(narrative: "Un verano en el pueblo, con Marta cerca.", savedAt: Date()))
    let memoryOther = try #require(
      Memory(narrative: "Marta me llevó a conocer el pueblo.", savedAt: Date()))
    let marta = try #require(Element(displayName: "Marta", type: .person))
    let village = try #require(Element(displayName: "el pueblo", type: .place))

    let appearances = [
      // In the global array and in memoryOther, "el pueblo" comes before "Marta"...
      Appearance(
        memoryID: memoryOther.id, elementID: village.id, role: nil, status: .confirmedByUser),
      // ...but in the origin's own appearances, "Marta" comes before "el pueblo".
      Appearance(
        memoryID: memoryOrigin.id, elementID: marta.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryOther.id, elementID: marta.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryOrigin.id, elementID: village.id, role: nil, status: .confirmedByUser),
    ]

    let result = MemoryConnections.connected(to: memoryOrigin, appearances: appearances)
    #expect(
      result == [MemoryConnection(memoryID: memoryOther.id, motives: [marta.id, village.id])])
  }

  @Test func `status and role never affect whether an appearance counts toward a connection`()
    throws
  {
    // Neither status nor role filters the connection.
    let memoryA = try #require(Memory(narrative: "Un paseo con José.", savedAt: Date()))
    let memoryB = try #require(Memory(narrative: "José, siempre puntual.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))
    let guestRole = try #require(ElementRole(text: "invitado"))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: jose.id, role: nil, status: .proposed),
      Appearance(
        memoryID: memoryB.id, elementID: jose.id, role: guestRole, status: .proposed),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(result == [MemoryConnection(memoryID: memoryB.id, motives: [jose.id])])
  }

  @Test
  func
    `a duplicate appearance row for the same element never duplicates the connection or its motives`()
    throws
  {
    let memoryA = try #require(Memory(narrative: "Un domingo con José.", savedAt: Date()))
    let memoryB = try #require(Memory(narrative: "José otra vez de visita.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))

    let appearances = [
      Appearance(memoryID: memoryA.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: jose.id, role: nil, status: .proposed),
    ]

    let result = MemoryConnections.connected(to: memoryA, appearances: appearances)
    #expect(result == [MemoryConnection(memoryID: memoryB.id, motives: [jose.id])])
  }

  @Test func `the same input always produces the same result, same order included`() throws {
    // Determinism: same data, same result and same order, every time.
    let memoryOrigin = try #require(
      Memory(narrative: "Una tarde en el mercado, con el reloj en el bolsillo.", savedAt: Date()))
    let memoryB = try #require(Memory(narrative: "Recuperé el reloj perdido.", savedAt: Date()))
    let memoryC = try #require(Memory(narrative: "Volví al mercado de siempre.", savedAt: Date()))
    let clock = try #require(Element(displayName: "el reloj", type: .object))
    let market = try #require(Element(displayName: "el mercado", type: .place))

    let appearances = [
      Appearance(
        memoryID: memoryOrigin.id, elementID: clock.id, role: nil, status: .confirmedByUser),
      Appearance(
        memoryID: memoryOrigin.id, elementID: market.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryC.id, elementID: market.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: memoryB.id, elementID: clock.id, role: nil, status: .confirmedByUser),
    ]

    let first = MemoryConnections.connected(to: memoryOrigin, appearances: appearances)
    let second = MemoryConnections.connected(to: memoryOrigin, appearances: appearances)
    #expect(first == second)
  }
}
