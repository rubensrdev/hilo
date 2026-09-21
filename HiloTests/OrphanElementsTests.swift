import Testing

@testable import Hilo

// contrato 6 + reglas 9, 11, 12: un elemento sin ninguna aparicion deja de existir
nonisolated struct OrphanElementsTests {
  @Test func `an element that only appeared in a deleted memory is orphaned, others are not`()
    throws
  {
    // caso del spec, linea 145
    let onlyInDeleted = try #require(Element(displayName: "un cuaderno", type: .object))
    let alsoElsewhere = try #require(Element(displayName: "José", type: .person))
    let remainingMemoryID = MemoryID()

    // el recuerdo borrado ya no deja filas de Appearance en el array
    let appearances = [
      Appearance(
        memoryID: remainingMemoryID, elementID: alsoElsewhere.id, role: nil,
        status: .confirmedByUser)
    ]

    let result = OrphanElements.among([onlyInDeleted, alsoElsewhere], appearances: appearances)
    #expect(result == [onlyInDeleted.id])
  }

  @Test func `an element with at least one remaining appearance anywhere is never orphaned`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let firstMemory = MemoryID()
    let secondMemory = MemoryID()

    let appearances = [
      Appearance(memoryID: firstMemory, elementID: jose.id, role: nil, status: .confirmedByUser),
      Appearance(memoryID: secondMemory, elementID: jose.id, role: nil, status: .proposed),
    ]

    let result = OrphanElements.among([jose], appearances: appearances)
    #expect(result.isEmpty)
  }

  @Test func `with no appearances at all, every element is orphaned`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let clock = try #require(Element(displayName: "el reloj", type: .object))

    let result = OrphanElements.among([jose, clock], appearances: [])
    #expect(result == [jose.id, clock.id])
  }

  @Test func `no elements at all produces an empty list, not an error`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let appearances = [
      Appearance(memoryID: MemoryID(), elementID: jose.id, role: nil, status: .confirmedByUser)
    ]

    let result = OrphanElements.among([], appearances: appearances)
    #expect(result.isEmpty)
  }

  @Test func `the same input always produces the same result, same order included`() throws {
    // contrato 8: determinismo — mismos datos, mismo resultado y mismo orden, siempre
    let jose = try #require(Element(displayName: "José", type: .person))
    let clock = try #require(Element(displayName: "el reloj", type: .object))
    let carmen = try #require(Element(displayName: "Carmen", type: .person))
    let appearances = [
      Appearance(memoryID: MemoryID(), elementID: carmen.id, role: nil, status: .confirmedByUser)
    ]

    let first = OrphanElements.among([jose, clock, carmen], appearances: appearances)
    let second = OrphanElements.among([jose, clock, carmen], appearances: appearances)
    #expect(first == second)
  }
}
