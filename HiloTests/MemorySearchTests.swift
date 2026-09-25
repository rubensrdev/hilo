import Foundation
import Testing

@testable import Hilo

nonisolated struct MemorySearchTests {
  static func memory(
    narrative: String, savedAt: Date = Date(timeIntervalSince1970: 0)
  ) throws -> Memory {
    try #require(Memory(narrative: narrative, savedAt: savedAt))
  }

  static func element(
    name: String, aliases: [String] = [], type: ElementType = .person
  ) throws -> Element {
    try #require(Element(displayName: name, type: type, aliases: aliases))
  }

  static func appearance(
    memoryID: MemoryID, elementID: ElementID, status: RecognitionStatus = .confirmedByUser
  ) -> Appearance {
    Appearance(memoryID: memoryID, elementID: elementID, role: nil, status: status)
  }

  /// Independent oracle: Foundation's own search, not MemorySearch's internal logic.
  static func allRanges(of query: String, in text: String) -> [Range<String.Index>] {
    var ranges: [Range<String.Index>] = []
    var searchStart = text.startIndex
    while let found = text.range(
      of: query, options: [.caseInsensitive, .diacriticInsensitive],
      range: searchStart..<text.endIndex)
    {
      ranges.append(found)
      searchStart = found.upperBound
    }
    return ranges
  }

  static func defaultClipEnd(of narrative: String, length: Int) -> String.Index {
    narrative.index(narrative.startIndex, offsetBy: min(length, narrative.count))
  }

  // MARK: results — narrative match

  @Test
  func
    `a narrative match is diacritic and case insensitive, with an accurate range and the default extract`()
    throws
  {
    let defaultExtractLength = 200
    let memory = try Self.memory(narrative: "Una tarde de otoño paseamos por Cádiz, cerca del mar.")

    let results = MemorySearch.results(
      for: "cadiz", in: [memory], elements: [], appearances: [],
      defaultExtractLength: defaultExtractLength)

    let result = try #require(results.first)
    #expect(result.memoryID == memory.id)
    #expect(result.matchedElementIDs == [])

    let match = try #require(result.narrativeMatches.first)
    #expect(memory.narrative[match] == "Cádiz")

    let expectedEnd = Self.defaultClipEnd(of: memory.narrative, length: defaultExtractLength)
    #expect(result.extract == memory.narrative.startIndex..<expectedEnd)
  }

  // MARK: results — linked element match

  @Test
  func
    `a memory matching only through a linked element's name has no narrative match but includes the element`()
    throws
  {
    let memory = try Self.memory(narrative: "Una comida tranquila en la terraza.")
    let carmen = try Self.element(name: "Carmen")
    let appearances = [Self.appearance(memoryID: memory.id, elementID: carmen.id)]

    let results = MemorySearch.results(
      for: "carmen", in: [memory], elements: [carmen], appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(result.narrativeMatches == [])
    #expect(result.extract == nil)
    #expect(result.matchedElementIDs == [carmen.id])
  }

  @Test
  func
    `a memory matching only through a linked element's alias has no narrative match but includes the element`()
    throws
  {
    let memory = try Self.memory(narrative: "Una tarde jugando al dominó.")
    let element = try Self.element(name: "José Ramón", aliases: ["Pepe"])
    let appearances = [Self.appearance(memoryID: memory.id, elementID: element.id)]

    let results = MemorySearch.results(
      for: "pepe", in: [memory], elements: [element], appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(result.narrativeMatches == [])
    #expect(result.extract == nil)
    #expect(result.matchedElementIDs == [element.id])
  }

  @Test func `an alias match is also diacritic and case insensitive`() throws {
    let memory = try Self.memory(narrative: "Una tarde jugando al dominó con el vecino.")
    let element = try Self.element(name: "el vecino", aliases: ["Ángel"])
    let appearances = [Self.appearance(memoryID: memory.id, elementID: element.id)]

    let results = MemorySearch.results(
      for: "ANGEL", in: [memory], elements: [element], appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(result.matchedElementIDs == [element.id])
  }

  // MARK: results — no match

  @Test
  func
    `a memory with no match anywhere, neither narrative nor element, is absent from the results`()
    throws
  {
    let memory = try Self.memory(narrative: "Una tarde tranquila sin nada especial.")
    let carmen = try Self.element(name: "Carmen")
    let appearances = [Self.appearance(memoryID: memory.id, elementID: carmen.id)]

    let results = MemorySearch.results(
      for: "reloj", in: [memory], elements: [carmen], appearances: appearances,
      defaultExtractLength: 100)

    #expect(results.isEmpty)
  }

  // MARK: results — filtering linked elements

  @Test
  func
    `a linked element that does not match the query is excluded even when another one in the same memory matches`()
    throws
  {
    let memory = try Self.memory(narrative: "Un paseo con José por el parque.")
    let jose = try Self.element(name: "José")
    let carmen = try Self.element(name: "Carmen")
    let appearances = [
      Self.appearance(memoryID: memory.id, elementID: jose.id),
      Self.appearance(memoryID: memory.id, elementID: carmen.id),
    ]

    let results = MemorySearch.results(
      for: "carmen", in: [memory], elements: [jose, carmen], appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(result.matchedElementIDs == [carmen.id])
  }

  @Test
  func
    `an element matching the query but linked to a different memory never leaks into this memory's result`()
    throws
  {
    let memoryA = try Self.memory(narrative: "Una mañana cualquiera sin nada que contar.")
    let memoryB = try Self.memory(narrative: "Carmen vino a visitarnos.")
    let carmen = try Self.element(name: "Carmen")
    let appearances = [Self.appearance(memoryID: memoryB.id, elementID: carmen.id)]

    let results = MemorySearch.results(
      for: "carmen", in: [memoryA, memoryB], elements: [carmen], appearances: appearances,
      defaultExtractLength: 100)

    // memoryA neither links Carmen nor mentions her: out of the results.
    #expect(!results.contains { $0.memoryID == memoryA.id })
    // memoryB does mention her in the narrative.
    #expect(results.contains { $0.memoryID == memoryB.id })
  }

  @Test
  func `duplicate appearance rows for the same element never duplicate it in matchedElementIDs`()
    throws
  {
    let memory = try Self.memory(narrative: "Una tarde de dominó.")
    let jose = try Self.element(name: "José")
    let appearances = [
      Self.appearance(memoryID: memory.id, elementID: jose.id, status: .confirmedByUser),
      Self.appearance(memoryID: memory.id, elementID: jose.id, status: .proposed),
    ]

    let results = MemorySearch.results(
      for: "jose", in: [memory], elements: [jose], appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(result.matchedElementIDs == [jose.id])
  }

  @Test
  func
    `six or more matching elements in one memory are all returned, uncapped, in appearance order`()
    throws
  {
    // No cap on matching elements.
    let memory = try Self.memory(narrative: "Una comida familiar cualquiera.")
    let names = ["Ana Pérez", "Ana Gómez", "Ana Luisa", "Ana Belén", "Ana Sofía", "Ana María"]
    let people = try names.map { try Self.element(name: $0) }
    let appearances = people.map { Self.appearance(memoryID: memory.id, elementID: $0.id) }

    let results = MemorySearch.results(
      for: "ana", in: [memory], elements: people, appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(result.matchedElementIDs == people.map(\.id))
    #expect(result.matchedElementIDs.count == 6)
  }

  @Test func `a memory matching by both narrative and element has both fields populated`() throws {
    let memory = try Self.memory(narrative: "José vino a comer con nosotros.")
    let jose = try Self.element(name: "José")
    let appearances = [Self.appearance(memoryID: memory.id, elementID: jose.id)]

    let results = MemorySearch.results(
      for: "jose", in: [memory], elements: [jose], appearances: appearances,
      defaultExtractLength: 100)

    let result = try #require(results.first)
    #expect(!result.narrativeMatches.isEmpty)
    #expect(result.extract != nil)
    #expect(!result.matchedElementIDs.isEmpty)
  }

  // MARK: results — order, empty query, empty list, determinism

  @Test func `results follow Memory ordering, filtered to only the memories that match`() throws {
    let matchingOld = try Self.memory(
      narrative: "Un reloj antiguo en la repisa.", savedAt: Date(timeIntervalSince1970: 0))
    let matchingNew = try Self.memory(
      narrative: "El reloj de la abuela.", savedAt: Date(timeIntervalSince1970: 1000))
    let nonMatching = try Self.memory(
      narrative: "Una tarde sin nada especial.", savedAt: Date(timeIntervalSince1970: 500))

    let all = [nonMatching, matchingOld, matchingNew]
    let results = MemorySearch.results(
      for: "reloj", in: all, elements: [], appearances: [], defaultExtractLength: 100)

    // Independent oracle: the same criterion Memory.isOrderedBefore already defines and tests.
    let expectedOrder = [matchingOld, matchingNew].sorted(by: Memory.isOrderedBefore).map(\.id)
    #expect(results.map(\.memoryID) == expectedOrder)
    #expect(!results.contains { $0.memoryID == nonMatching.id })
  }

  @Test func `an empty or whitespace-only query produces no results`() throws {
    let memory = try Self.memory(narrative: "Un recuerdo cualquiera con reloj.")

    #expect(
      MemorySearch.results(
        for: "", in: [memory], elements: [], appearances: [], defaultExtractLength: 100
      ).isEmpty)
    #expect(
      MemorySearch.results(
        for: "   ", in: [memory], elements: [], appearances: [], defaultExtractLength: 100
      ).isEmpty)
  }

  @Test func `an empty memories list produces no results regardless of the query`() {
    #expect(
      MemorySearch.results(
        for: "reloj", in: [], elements: [], appearances: [], defaultExtractLength: 100
      ).isEmpty)
  }

  @Test func `calling results twice with the same input yields the same result`() throws {
    let memory = try Self.memory(narrative: "Una tarde con José y su reloj.")
    let jose = try Self.element(name: "José")
    let appearances = [Self.appearance(memoryID: memory.id, elementID: jose.id)]

    let first = MemorySearch.results(
      for: "jose", in: [memory], elements: [jose], appearances: appearances,
      defaultExtractLength: 100)
    let second = MemorySearch.results(
      for: "jose", in: [memory], elements: [jose], appearances: appearances,
      defaultExtractLength: 100)

    #expect(first == second)
  }

  // MARK: narrativeMatches — called directly

  @Test func `narrativeMatches finds two non-overlapping occurrences at the right positions`()
    throws
  {
    let narrative = "El reloj sonó y después otro reloj respondió a lo lejos."

    let matches = MemorySearch.narrativeMatches(of: "reloj", in: narrative)
    let expected = Self.allRanges(of: "reloj", in: narrative)

    #expect(matches == expected)
    #expect(matches.count == 2)
  }

  // MARK: extractRange — called directly, default clip versus centred

  @Test func `extractRange returns the default clip when the first match starts within the budget`()
    throws
  {
    let defaultExtractLength = 40
    let narrative =
      "Aquella tarde el reloj sonó justo antes de la cena, con todos reunidos en la sala."

    let matches = MemorySearch.narrativeMatches(of: "reloj", in: narrative)
    #expect(!matches.isEmpty)

    let extract = MemorySearch.extractRange(
      in: narrative, matches: matches, defaultExtractLength: defaultExtractLength)

    let expectedEnd = Self.defaultClipEnd(of: narrative, length: defaultExtractLength)
    #expect(extract == narrative.startIndex..<expectedEnd)
  }

  @Test func `extractRange centers on the first match when it starts beyond the budget`() throws {
    let defaultExtractLength = 30
    let narrative =
      "Recuerdo aquella mañana de invierno, cuando salimos temprano de casa y al final "
      + "encontramos el reloj perdido debajo del sofá, justo donde lo habíamos dejado la última vez."

    let matches = MemorySearch.narrativeMatches(of: "reloj", in: narrative)
    let firstMatch = try #require(matches.first)

    // Confirms the premise: the match starts outside the default clip.
    let defaultEnd = Self.defaultClipEnd(of: narrative, length: defaultExtractLength)
    #expect(firstMatch.lowerBound >= defaultEnd)

    let extract = MemorySearch.extractRange(
      in: narrative, matches: matches, defaultExtractLength: defaultExtractLength)

    #expect(extract != narrative.startIndex..<defaultEnd)
    #expect(extract.contains(firstMatch.lowerBound))
    #expect(firstMatch.upperBound <= extract.upperBound)
    #expect(narrative[extract].count == min(defaultExtractLength, narrative.count))
  }

  @Test
  func
    `the boundary between inside and outside the default clip falls exactly at defaultExtractLength characters`()
    throws
  {
    let defaultExtractLength = 30
    // Synthetic filler to fix the match's exact offset; not a real memory.
    let insideFiller = String(repeating: "a", count: defaultExtractLength - 1)
    let outsideFiller = String(repeating: "a", count: defaultExtractLength)
    let tail = " y más cosas alrededor para que el relato sea suficientemente largo."

    let narrativeInside = insideFiller + "reloj" + tail
    let narrativeOutside = outsideFiller + "reloj" + tail

    let matchesInside = MemorySearch.narrativeMatches(of: "reloj", in: narrativeInside)
    let matchesOutside = MemorySearch.narrativeMatches(of: "reloj", in: narrativeOutside)

    let extractInside = MemorySearch.extractRange(
      in: narrativeInside, matches: matchesInside, defaultExtractLength: defaultExtractLength)
    let extractOutside = MemorySearch.extractRange(
      in: narrativeOutside, matches: matchesOutside, defaultExtractLength: defaultExtractLength)

    let defaultEndInside = Self.defaultClipEnd(
      of: narrativeInside, length: defaultExtractLength)
    let defaultEndOutside = Self.defaultClipEnd(
      of: narrativeOutside, length: defaultExtractLength)

    // Offset defaultExtractLength - 1: inside the default clip, so the default extract.
    #expect(extractInside == narrativeInside.startIndex..<defaultEndInside)
    // Offset defaultExtractLength: one character further, no longer the default clip.
    #expect(extractOutside != narrativeOutside.startIndex..<defaultEndOutside)
  }

  @Test
  func
    `centering near the end of a short narrative uses the full budget without spilling past the end`()
    throws
  {
    let defaultExtractLength = 30
    // A narrative just longer than the budget, with the match near the end.
    let filler = String(repeating: "x", count: defaultExtractLength)
    let narrative = filler + "reloj"

    let matches = MemorySearch.narrativeMatches(of: "reloj", in: narrative)
    let match = try #require(matches.first)

    let extract = MemorySearch.extractRange(
      in: narrative, matches: matches, defaultExtractLength: defaultExtractLength)

    let expectedLength = min(defaultExtractLength, narrative.count)
    #expect(narrative[extract].count == expectedLength)
    #expect(extract.upperBound == narrative.endIndex)
    #expect(extract.contains(match.lowerBound))
    #expect(match.upperBound <= extract.upperBound)
  }
}
