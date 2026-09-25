import Foundation
import Testing

@testable import Hilo

nonisolated struct MemoryTests {
  /// savedAt is system data with no default: always fixed, never Date().
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

  /// The rebuild init keeps the validated id; the failable init always creates a new one.
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
