import Testing

@testable import Hilo

nonisolated struct ElementRoleTests {
  @Test(arguments: ["", "   ", "\n\t"])
  func `rejects a blank role`(text: String) {
    #expect(ElementRole(text: text) == nil)
  }

  @Test func `preserves the role text exactly as written, without trimming or reformatting`() throws
  {
    let original = "  el reloj   que llevaba puesto  "
    let role = try #require(ElementRole(text: original))
    #expect(role.text == original)
  }
}
