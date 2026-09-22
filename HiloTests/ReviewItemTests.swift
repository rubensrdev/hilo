import Testing

@testable import Hilo

// contrato 2: el candidato de revision es la puerta de entrada, y la identidad nace de la resolucion pura
nonisolated struct ReviewItemTests {
  @Test(arguments: ["", "   ", "\n\t"])
  func `rejects a blank candidate name`(name: String) {
    #expect(ReviewCandidate(name: name, type: .object, role: nil) == nil)
  }

  @Test func `preserves name, type and role for a well-formed candidate`() throws {
    let role = try #require(ElementRole(text: "mi hermano"))
    let candidate = try #require(ReviewCandidate(name: "Pablo", type: .person, role: role))
    #expect(candidate.name == "Pablo")
    #expect(candidate.type == .person)
    #expect(candidate.role?.text == "mi hermano")
  }

  @Test func `accepts a candidate with no role at all`() throws {
    let candidate = try #require(ReviewCandidate(name: "el reloj", type: .object, role: nil))
    #expect(candidate.role == nil)
  }

  @Test
  func `an exact match resolution becomes a non-rejected recognition with the same element ids`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let identity = ReviewIdentity(.exactMatch([jose.id]))
    #expect(identity == .recognized([jose.id], rejected: false))
  }

  @Test func `an identity doubt resolution becomes an unanswered doubt with the same candidates`()
    throws
  {
    let jose = try #require(Element(displayName: "José", type: .person))
    let identity = ReviewIdentity(.identityDoubt([jose.id]))
    #expect(identity == .doubt(candidates: [jose.id], answer: nil))
  }

  @Test func `a new resolution becomes a new identity`() {
    let identity = ReviewIdentity(.new)
    #expect(identity == .new)
  }
}
