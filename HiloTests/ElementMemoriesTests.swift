import Foundation
import Testing

@testable import Hilo

// contrato 4 (lista de elementos): cuantos recuerdos distintos tiene un elemento, sin duplicar
// por fila de aparicion — misma forma de deduplicado que MemorySearch.matchingElementIDs
nonisolated struct ElementMemoriesTests {
  static func element(name: String, type: ElementType = .person) throws -> Element {
    try #require(Element(displayName: name, type: type))
  }

  static func memory(narrative: String) throws -> Memory {
    try #require(Memory(narrative: narrative, savedAt: Date(timeIntervalSince1970: 0)))
  }

  static func appearance(
    memoryID: MemoryID, elementID: ElementID, status: RecognitionStatus = .confirmedByUser
  ) -> Appearance {
    Appearance(memoryID: memoryID, elementID: elementID, role: nil, status: status)
  }

  @Test func `no appearances at all produce zero memories and an empty id list`() throws {
    let jose = try Self.element(name: "José")

    #expect(ElementMemories.memoryIDs(for: jose.id, in: []) == [])
    #expect(ElementMemories.count(for: jose.id, in: []) == 0)
  }

  @Test func `appearances of other elements only never count for this one`() throws {
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    let onlyMemory = try Self.memory(narrative: "Una tarde con Carmen en el parque.")
    let appearances = [Self.appearance(memoryID: onlyMemory.id, elementID: carmen.id)]

    #expect(ElementMemories.memoryIDs(for: jose.id, in: appearances) == [])
    #expect(ElementMemories.count(for: jose.id, in: appearances) == 0)
  }

  @Test func `one appearance in one memory counts as one`() throws {
    let jose = try Self.element(name: "José")
    let onlyMemory = try Self.memory(narrative: "El abuelo José nos llevó al río.")
    let appearances = [Self.appearance(memoryID: onlyMemory.id, elementID: jose.id)]

    #expect(ElementMemories.memoryIDs(for: jose.id, in: appearances) == [onlyMemory.id])
    #expect(ElementMemories.count(for: jose.id, in: appearances) == 1)
  }

  @Test
  func
    `several distinct memories produce the correct count and id set, in first-appearance order`()
    throws
  {
    let jose = try Self.element(name: "José")
    let first = try Self.memory(narrative: "José y el reloj.")
    let second = try Self.memory(narrative: "José en la casa del pueblo.")
    let third = try Self.memory(narrative: "José y la máquina de coser.")
    let appearances = [
      Self.appearance(memoryID: first.id, elementID: jose.id),
      Self.appearance(memoryID: second.id, elementID: jose.id),
      Self.appearance(memoryID: third.id, elementID: jose.id),
    ]

    #expect(
      ElementMemories.memoryIDs(for: jose.id, in: appearances) == [first.id, second.id, third.id])
    #expect(ElementMemories.count(for: jose.id, in: appearances) == 3)
  }

  @Test func `two appearances of the same element in the same memory count once, not twice`()
    throws
  {
    let jose = try Self.element(name: "José")
    let onlyMemory = try Self.memory(narrative: "José aparece con dos roles en el mismo relato.")
    let appearances = [
      Self.appearance(memoryID: onlyMemory.id, elementID: jose.id, status: .confirmedByUser),
      Self.appearance(memoryID: onlyMemory.id, elementID: jose.id, status: .proposed),
    ]

    #expect(ElementMemories.memoryIDs(for: jose.id, in: appearances) == [onlyMemory.id])
    #expect(ElementMemories.count(for: jose.id, in: appearances) == 1)
  }

  @Test
  func
    `appearances of the target element interleaved with another element only pick up the target's`()
    throws
  {
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    let first = try Self.memory(narrative: "José y Carmen en la comida.")
    let second = try Self.memory(narrative: "José y Carmen en la boda.")
    // orden deliberadamente intercalado entre los dos elementos
    let appearances = [
      Self.appearance(memoryID: first.id, elementID: carmen.id),
      Self.appearance(memoryID: first.id, elementID: jose.id),
      Self.appearance(memoryID: second.id, elementID: carmen.id),
      Self.appearance(memoryID: second.id, elementID: jose.id),
    ]

    #expect(ElementMemories.memoryIDs(for: jose.id, in: appearances) == [first.id, second.id])
    #expect(ElementMemories.count(for: jose.id, in: appearances) == 2)
  }

  @Test func `calling memoryIDs twice with the same input yields the same result`() throws {
    let jose = try Self.element(name: "José")
    let onlyMemory = try Self.memory(narrative: "José y el reloj sin cuerda.")
    let appearances = [Self.appearance(memoryID: onlyMemory.id, elementID: jose.id)]

    #expect(
      ElementMemories.memoryIDs(for: jose.id, in: appearances)
        == ElementMemories.memoryIDs(for: jose.id, in: appearances))
  }
}
