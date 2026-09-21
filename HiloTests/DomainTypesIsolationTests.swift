import Foundation
import Testing

@testable import Hilo

// contrato 8 + criterio de aceptación: si el dominio pierde `nonisolated`, este fichero deja de compilar
nonisolated struct DomainTypesIsolationTests {
  static let fixedSavedAt = Date(timeIntervalSince1970: 0)

  @Test func `Domain value types construct and compute without awaiting the main actor`() throws {
    #expect(Element(displayName: "   ", type: .object) == nil)
    let dated = try #require(MemoryDate(text: "el verano del 87", deducedYear: 1987))
    let undated = try #require(MemoryDate(text: "no me acuerdo del año, pero fue en otoño"))
    let datedMemory = try #require(
      Memory(
        narrative: "Paseamos por el Albaicín al atardecer.", date: dated, savedAt: Self.fixedSavedAt
      ))
    let undatedMemory = try #require(
      Memory(
        narrative: "Comimos en la plaza sin apuntar el año.", date: undated,
        savedAt: Self.fixedSavedAt))
    #expect(Memory.isOrderedBefore(datedMemory, undatedMemory))
  }

  @Test func `Domain values cross a detached task boundary as Sendable`() async throws {
    let dated = try #require(MemoryDate(text: "el verano del 87", deducedYear: 1987))
    let undated = try #require(MemoryDate(text: "no me acuerdo del año, pero fue en otoño"))
    let memory = try #require(
      Memory(
        narrative: "Paseamos por el Albaicín al atardecer.", date: dated, savedAt: Self.fixedSavedAt
      ))
    let otherMemory = try #require(
      Memory(
        narrative: "Comimos en la plaza sin apuntar el año.", date: undated,
        savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Granada", type: .place))
    let role = try #require(ElementRole(text: "el lugar que visitamos"))
    let appearance = Appearance(
      memoryID: memory.id, elementID: element.id, role: role, status: .confirmedByUser)

    let result = await Task.detached {
      appearance.role?.text == role.text && Memory.isOrderedBefore(memory, otherMemory)
    }.value

    #expect(result)
  }
}
