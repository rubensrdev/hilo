import Foundation
import Testing

@testable import Hilo

nonisolated struct MemoryElementsTests {
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

  @Test func `a memory with no appearances at all produces an empty list`() throws {
    let onlyMemory = try Self.memory(narrative: "Un recuerdo sin ningun elemento reconocido.")

    #expect(MemoryElements.elementIDs(for: onlyMemory.id, in: []) == [])
  }

  @Test func `appearances of other memories only never count for this one`() throws {
    let target = try Self.memory(narrative: "Un paseo por el puerto.")
    let other = try Self.memory(narrative: "Una tarde con Carmen en el parque.")
    let carmen = try Self.element(name: "Carmen")
    let appearances = [Self.appearance(memoryID: other.id, elementID: carmen.id)]

    #expect(MemoryElements.elementIDs(for: target.id, in: appearances) == [])
  }

  @Test func `one appearance produces a list with that single element`() throws {
    let target = try Self.memory(narrative: "El abuelo José nos llevó al río.")
    let jose = try Self.element(name: "José")
    let appearances = [Self.appearance(memoryID: target.id, elementID: jose.id)]

    #expect(MemoryElements.elementIDs(for: target.id, in: appearances) == [jose.id])
  }

  @Test func `several elements are returned in order of first appearance`() throws {
    let target = try Self.memory(narrative: "José y Carmen fueron con el reloj al pueblo.")
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    let clock = try Self.element(name: "el reloj", type: .object)
    let appearances = [
      Self.appearance(memoryID: target.id, elementID: jose.id),
      Self.appearance(memoryID: target.id, elementID: carmen.id),
      Self.appearance(memoryID: target.id, elementID: clock.id),
    ]

    #expect(
      MemoryElements.elementIDs(for: target.id, in: appearances) == [jose.id, carmen.id, clock.id])
  }

  @Test func `two appearances of the same element in the same memory count once, not twice`()
    throws
  {
    let target = try Self.memory(narrative: "José aparece con dos roles en el mismo relato.")
    let jose = try Self.element(name: "José")
    let appearances = [
      Self.appearance(memoryID: target.id, elementID: jose.id, status: .confirmedByUser),
      Self.appearance(memoryID: target.id, elementID: jose.id, status: .proposed),
    ]

    #expect(MemoryElements.elementIDs(for: target.id, in: appearances) == [jose.id])
  }

  @Test
  func
    `appearances of the target memory interleaved with another memory only pick up the target's`()
    throws
  {
    let target = try Self.memory(narrative: "José y Carmen en la comida.")
    let other = try Self.memory(narrative: "José y Carmen en la boda.")
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    // Deliberately interleaved between the two memories.
    let appearances = [
      Self.appearance(memoryID: other.id, elementID: jose.id),
      Self.appearance(memoryID: target.id, elementID: jose.id),
      Self.appearance(memoryID: other.id, elementID: carmen.id),
      Self.appearance(memoryID: target.id, elementID: carmen.id),
    ]

    #expect(MemoryElements.elementIDs(for: target.id, in: appearances) == [jose.id, carmen.id])
  }

  @Test func `calling elementIDs twice with the same input yields the same result`() throws {
    let target = try Self.memory(narrative: "José y el reloj sin cuerda.")
    let jose = try Self.element(name: "José")
    let appearances = [Self.appearance(memoryID: target.id, elementID: jose.id)]

    #expect(
      MemoryElements.elementIDs(for: target.id, in: appearances)
        == MemoryElements.elementIDs(for: target.id, in: appearances))
  }
}
