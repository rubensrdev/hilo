import Testing

@testable import Hilo

nonisolated struct ReviewCandidateExtractionTests {
  @Test func `maps the extracted person type to the domain person type`() {
    #expect(ElementType(ExtractedElementType.person) == .person)
  }

  @Test func `maps the extracted place type to the domain place type`() {
    #expect(ElementType(ExtractedElementType.place) == .place)
  }

  @Test func `maps the extracted object type to the domain object type`() {
    #expect(ElementType(ExtractedElementType.object) == .object)
  }

  @Test func `bridges an extracted element with an empty role into a candidate with a nil role`()
    throws
  {
    let extracted = ExtractedElement(name: "el reloj", type: .object, role: "")
    let candidate = try #require(ReviewCandidate(extracted))
    #expect(candidate.name == "el reloj")
    #expect(candidate.type == .object)
    #expect(candidate.role == nil)
  }

  @Test func `bridges an extracted element's role into the candidate's role, unchanged`() throws {
    let extracted = ExtractedElement(name: "Pablo", type: .person, role: "mi hermano")
    let candidate = try #require(ReviewCandidate(extracted))
    #expect(candidate.role?.text == "mi hermano")
  }

  @Test func `bridging fails when the extracted element has a blank name`() {
    let extracted = ExtractedElement(name: "   ", type: .person, role: "mi hermano")
    #expect(ReviewCandidate(extracted) == nil)
  }

  @Test
  func
    `building a review state from an extracted memory produces one item per extracted element, in order`()
    throws
  {
    let extracted = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Pablo", type: .person, role: "mi hermano"),
        ExtractedElement(name: "la abuela", type: .person, role: "quien cocinó"),
        ExtractedElement(name: "el patio", type: .place, role: "donde cenamos"),
      ],
      dateText: "aquel domingo", deducedYear: nil)

    let state = ReviewState(extracted: extracted, knownElements: [], appearances: [])

    #expect(state.items.map(\.originalName) == ["Pablo", "la abuela", "el patio"])
    #expect(state.items.map(\.type) == [.person, .person, .place])
    #expect(state.extractedDateText == "aquel domingo")
    #expect(state.extractedDeducedYear == nil)
  }
}
