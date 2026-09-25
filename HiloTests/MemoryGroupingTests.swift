import Foundation
import Testing

@testable import Hilo

nonisolated struct MemoryGroupingTests {
  static func memory(
    year: Int? = nil, savedAt: Date = Date(timeIntervalSince1970: 0),
    narrative: String = "Un recuerdo cualquiera."
  ) throws -> Memory {
    let date: MemoryDate?
    if let year {
      date = MemoryDate(text: "un año cualquiera", deducedYear: year)
    } else {
      date = MemoryDate(text: "no recuerdo el año")
    }
    return try #require(Memory(narrative: narrative, date: date, savedAt: savedAt))
  }

  /// Independent oracle: decade start by integer division, never MemoryGrouping itself.
  static func decadeStart(_ year: Int) -> Int {
    (year / 10) * 10
  }

  @Test func `an empty list produces no groups`() {
    #expect(MemoryGrouping.grouped([]) == [])
  }

  @Test func `a single dated memory produces one group with the correct decade start`() throws {
    let memory = try Self.memory(year: 1987)

    let groups = MemoryGrouping.grouped([memory])

    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1987)), memories: [memory])
      ])
  }

  @Test func `a single undated memory produces one no-year group`() throws {
    let memory = try Self.memory()

    let groups = MemoryGrouping.grouped([memory])

    #expect(groups == [MemoryGroup(decade: .noYear, memories: [memory])])
  }

  @Test func `two memories in the same decade land in a single group, internally ordered`()
    throws
  {
    let older = try Self.memory(year: 1982, savedAt: Date(timeIntervalSince1970: 0))
    let newer = try Self.memory(year: 1988, savedAt: Date(timeIntervalSince1970: 100))

    let groups = MemoryGrouping.grouped([older, newer])

    // Independent oracle: the same order Memory.isOrderedBefore already defines and tests.
    let expectedOrder = [older, newer].sorted(by: Memory.isOrderedBefore)
    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1982)), memories: expectedOrder)
      ])
  }

  @Test func `two memories in different decades produce two groups, most recent first`() throws {
    let old = try Self.memory(year: 1975)
    let recent = try Self.memory(year: 2015)

    let groups = MemoryGrouping.grouped([old, recent])

    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(2015)), memories: [recent]),
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1975)), memories: [old]),
      ])
  }

  @Test func `1979 and 1980 fall into separate, adjacent decades, the 1980s first`() throws {
    let seventyNine = try Self.memory(year: 1979)
    let eighty = try Self.memory(year: 1980)

    let groups = MemoryGrouping.grouped([seventyNine, eighty])

    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1980)), memories: [eighty]),
        MemoryGroup(
          decade: .decade(startingYear: Self.decadeStart(1979)), memories: [seventyNine]),
      ])
  }

  @Test func `1989 and 1990 fall into separate, adjacent decades, the 1990s first`() throws {
    let eightyNine = try Self.memory(year: 1989)
    let ninety = try Self.memory(year: 1990)

    let groups = MemoryGrouping.grouped([eightyNine, ninety])

    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1990)), memories: [ninety]),
        MemoryGroup(
          decade: .decade(startingYear: Self.decadeStart(1989)), memories: [eightyNine]),
      ])
  }

  @Test
  func
    `a shuffled mix of decades and undated memories groups decade-descending with no-year last`()
    throws
  {
    let m1990s = try Self.memory(year: 1995, savedAt: Date(timeIntervalSince1970: 0))
    let m1980s = try Self.memory(year: 1983, savedAt: Date(timeIntervalSince1970: 0))
    let m2020s = try Self.memory(year: 2022, savedAt: Date(timeIntervalSince1970: 0))
    let undatedA = try Self.memory(savedAt: Date(timeIntervalSince1970: 10))
    let undatedB = try Self.memory(savedAt: Date(timeIntervalSince1970: 20))

    // Input deliberately shuffled.
    let input = [undatedA, m1990s, m2020s, undatedB, m1980s]
    let groups = MemoryGrouping.grouped(input)

    let expectedUndatedOrder = [undatedA, undatedB].sorted(by: Memory.isOrderedBefore)

    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(2022)), memories: [m2020s]),
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1995)), memories: [m1990s]),
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1983)), memories: [m1980s]),
        MemoryGroup(decade: .noYear, memories: expectedUndatedOrder),
      ])
  }

  @Test func `several undated memories collapse into a single no-year group, internally ordered`()
    throws
  {
    let a = try Self.memory(savedAt: Date(timeIntervalSince1970: 5))
    let b = try Self.memory(savedAt: Date(timeIntervalSince1970: 50))
    let c = try Self.memory(savedAt: Date(timeIntervalSince1970: 25))

    // Input shuffled.
    let groups = MemoryGrouping.grouped([b, a, c])

    let expectedOrder = [a, b, c].sorted(by: Memory.isOrderedBefore)
    #expect(groups == [MemoryGroup(decade: .noYear, memories: expectedOrder)])
  }

  @Test func `calling grouped twice with the same input yields the same result`() throws {
    let a = try Self.memory(year: 1960, savedAt: Date(timeIntervalSince1970: 0))
    let b = try Self.memory(savedAt: Date(timeIntervalSince1970: 1))
    let input = [a, b]

    #expect(MemoryGrouping.grouped(input) == MemoryGrouping.grouped(input))
  }

  @Test func `non-contiguous decades produce exactly the occupied groups, no synthetic gaps`()
    throws
  {
    let fifties = try Self.memory(year: 1955)
    let twenties = try Self.memory(year: 2021)

    let groups = MemoryGrouping.grouped([fifties, twenties])

    #expect(groups.count == 2)
    #expect(
      groups == [
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(2021)), memories: [twenties]),
        MemoryGroup(decade: .decade(startingYear: Self.decadeStart(1955)), memories: [fifties]),
      ])
  }
}
