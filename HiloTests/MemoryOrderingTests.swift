import Foundation
import Testing

@testable import Hilo

// regla 17 + contrato 7: el año solo ordena, nunca se muestra; el orden vive fuera de MemoryDate
nonisolated struct MemoryOrderingTests {
  static func memory(
    year: Int? = nil, savedAt: Date, narrative: String = "Un recuerdo cualquiera."
  ) throws -> Memory {
    let date: MemoryDate?
    if let year {
      date = MemoryDate(text: "un año cualquiera", deducedYear: year)
    } else {
      date = MemoryDate(text: "no recuerdo el año")
    }
    return try #require(Memory(narrative: narrative, date: date, savedAt: savedAt))
  }

  @Test func `two dated memories order by deduced year, descending`() throws {
    let earlier = try Self.memory(year: 1987, savedAt: Date(timeIntervalSince1970: 0))
    let later = try Self.memory(year: 2001, savedAt: Date(timeIntervalSince1970: 0))

    #expect(Memory.isOrderedBefore(later, earlier))
    #expect(!Memory.isOrderedBefore(earlier, later))
  }

  @Test func `dated memories tied on year break the tie by savedAt, descending`() throws {
    let sameYearOlderSave = try Self.memory(year: 1999, savedAt: Date(timeIntervalSince1970: 0))
    let sameYearNewerSave = try Self.memory(year: 1999, savedAt: Date(timeIntervalSince1970: 1000))

    #expect(Memory.isOrderedBefore(sameYearNewerSave, sameYearOlderSave))
    #expect(!Memory.isOrderedBefore(sameYearOlderSave, sameYearNewerSave))
  }

  @Test func `a dated memory always precedes an undated one, regardless of savedAt`() throws {
    let dated = try Self.memory(year: 1950, savedAt: Date(timeIntervalSince1970: 0))
    // la sin año se guardó mucho después, y aun así no debe adelantar a la que tiene año
    let undatedButSavedLater = try Self.memory(savedAt: Date(timeIntervalSince1970: 100_000))

    #expect(Memory.isOrderedBefore(dated, undatedButSavedLater))
    #expect(!Memory.isOrderedBefore(undatedButSavedLater, dated))
  }

  @Test func `two undated memories order by savedAt, descending`() throws {
    let olderSave = try Self.memory(savedAt: Date(timeIntervalSince1970: 0))
    let newerSave = try Self.memory(savedAt: Date(timeIntervalSince1970: 500))

    #expect(Memory.isOrderedBefore(newerSave, olderSave))
    #expect(!Memory.isOrderedBefore(olderSave, newerSave))
  }

  @Test func `dated memories tied on year and savedAt break the tie by id, reproducibly`() throws {
    let sharedSavedAt = Date(timeIntervalSince1970: 42)
    let first = try Self.memory(year: 2010, savedAt: sharedSavedAt)
    let second = try Self.memory(year: 2010, savedAt: sharedSavedAt)

    // oraculo independiente: mismo criterio de desempate (comparacion lexicografica del id), calculado aparte
    let expectedFirstBeforeSecond = first.id.value.uuidString < second.id.value.uuidString

    #expect(Memory.isOrderedBefore(first, second) == expectedFirstBeforeSecond)
    #expect(Memory.isOrderedBefore(second, first) == !expectedFirstBeforeSecond)

    // reproducible: repetir la llamada no cambia el resultado
    #expect(Memory.isOrderedBefore(first, second) == expectedFirstBeforeSecond)
    #expect(Memory.isOrderedBefore(first, second) != Memory.isOrderedBefore(second, first))
  }

  @Test func `undated memories tied on savedAt break the tie by id, reproducibly`() throws {
    let sharedSavedAt = Date(timeIntervalSince1970: 7)
    let first = try Self.memory(savedAt: sharedSavedAt)
    let second = try Self.memory(savedAt: sharedSavedAt)

    let expectedFirstBeforeSecond = first.id.value.uuidString < second.id.value.uuidString

    #expect(Memory.isOrderedBefore(first, second) == expectedFirstBeforeSecond)
    #expect(Memory.isOrderedBefore(second, first) == !expectedFirstBeforeSecond)
    #expect(Memory.isOrderedBefore(first, second) == expectedFirstBeforeSecond)
  }
}
