import Testing

@testable import Hilo

nonisolated struct ResemblanceTests {
  @Test func `José and José García resemble each other, same type`() {
    #expect(Resemblance.between("José", type: .person, "José García", type: .person))
  }

  @Test func `José and Josefa do not resemble, Josefa is not the complete word jose`() {
    #expect(!Resemblance.between("José", type: .person, "Josefa", type: .person))
  }

  @Test
  func
    `Ana and mañana do not resemble, mañana folds to manana without ana as a whole word`()
  {
    #expect(!Resemblance.between("Ana", type: .person, "mañana", type: .person))
  }

  @Test func `same canonical but different type never resembles, even letter for letter`() {
    // The same canonical name with a different type is not a resemblance.
    #expect(!Resemblance.between("Granada", type: .place, "Granada", type: .person))
  }

  @Test func `resemblance is symmetric regardless of argument order`() {
    let forward = Resemblance.between("José", type: .person, "José García", type: .person)
    let backward = Resemblance.between("José García", type: .person, "José", type: .person)
    #expect(forward)
    #expect(forward == backward)
  }

  @Test func `a name resembles itself when the type matches`() {
    #expect(Resemblance.between("Carmen", type: .person, "Carmen", type: .person))
  }
}
