import Foundation
import Testing

@testable import Hilo

// contrato 8 + regla 1: un recuerdo sin relato no existe, y el relato nunca se reescribe
nonisolated struct MemoryTests {
  // savedAt es un dato de sistema sin valor por defecto: siempre fijo, nunca Date()
  static let fixedSavedAt = Date(timeIntervalSince1970: 0)

  @Test(arguments: ["", "   ", "\n\t"])
  func `rejects a blank narrative`(narrative: String) {
    #expect(Memory(narrative: narrative, savedAt: Self.fixedSavedAt) == nil)
  }

  @Test func `preserves the narrative exactly as written, without trimming or reformatting`() throws
  {
    let original = "  Aquella tarde   fuimos al río,  \ny no volvimos hasta el anochecer.  "
    let memory = try #require(Memory(narrative: original, savedAt: Self.fixedSavedAt))
    #expect(memory.narrative == original)
  }

  @Test func `preserves the exact savedAt instant it was given`() throws {
    let memory = try #require(
      Memory(narrative: "Un paseo por la playa.", savedAt: Self.fixedSavedAt))
    #expect(memory.savedAt == Self.fixedSavedAt)
  }

  // F2.2: init de reconstruccion conserva el id ya validado; el failable siempre crea uno nuevo
  @Test
  func
    `The reconstruction init keeps the exact id it is given, unlike the failable init which always creates a new one`()
    throws
  {
    let memoryID = MemoryID()
    let reconstructed = Memory(
      id: memoryID, narrative: "Aprendí a nadar en la piscina del pueblo.",
      savedAt: Self.fixedSavedAt)
    #expect(reconstructed.id == memoryID)

    let freshlyCreated = try #require(
      Memory(narrative: "Aprendí a nadar en la piscina del pueblo.", savedAt: Self.fixedSavedAt))
    #expect(freshlyCreated.id != memoryID)
  }
}
