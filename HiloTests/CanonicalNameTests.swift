import Testing

@testable import Hilo

nonisolated struct CanonicalNameTests {
  @Test func `strips the article when it is not part of the name, la Alhambra becomes Alhambra`() {
    #expect(CanonicalName.of("La Alhambra") == "alhambra")
    #expect(CanonicalName.of("La Alhambra") == CanonicalName.of("Alhambra"))
  }

  @Test func `strips the initial article el from El Cairo`() {
    #expect(CanonicalName.of("El Cairo").contains("cairo"))
    #expect(CanonicalName.of("El Cairo") == "cairo")
  }

  @Test func `strips los and folds the accent, Los Angeles becomes angeles without the tilde`() {
    #expect(CanonicalName.of("Los Ángeles") == "angeles")
  }

  @Test func `keeps a lone article as the whole name when nothing is left behind`() {
    // The article is only dropped when another word follows it.
    #expect(CanonicalName.of("La") == "la")
  }

  @Test func `collapses multiple internal and edge spaces while folding accents`() {
    #expect(CanonicalName.of("  José    García  ") == "jose garcia")
  }

  @Test func `folds mixed uppercase and accents to plain lowercase`() {
    #expect(CanonicalName.of("JOSÉ García") == "jose garcia")
  }

  @Test func `strips the english article the, The Beatles becomes beatles`() {
    #expect(CanonicalName.of("The Beatles") == "beatles")
  }

  @Test func `strips the english possessive my, My Home becomes home`() {
    #expect(CanonicalName.of("My Home") == "home")
  }

  @Test func `only checks the first word, el inside Casa el Sol is not an article to strip`() {
    #expect(CanonicalName.of("Casa el Sol") == "casa el sol")
  }

  @Test func `strips only the first article once, La La Land keeps the second la`() {
    // Not recursive: only the first word is checked.
    #expect(CanonicalName.of("La La Land") == "la land")
  }

  @Test
  func
    `two names differing only in leading article, case and accents share the same canonical, end to end`()
  {
    #expect(CanonicalName.of("el Cairo") == CanonicalName.of("CAIRO"))
  }
}
