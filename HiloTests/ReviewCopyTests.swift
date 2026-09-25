import Foundation
import Testing

@testable import Hilo

// contrato 6 + anexo DEC-46: textos compuestos de la revision y del momento, en los dos idiomas
nonisolated struct ReviewCopyTests {
  private let english = Locale(identifier: "en")
  private let spanish = Locale(identifier: "es")

  // MARK: elemento — nombre, tipo y en cuantos recuerdos (contrato 6)

  @Test func `A known element announces name, type and its memories in English`() {
    #expect(
      ReviewCopy.elementLabel(name: "José", type: .person, otherMemories: 3, locale: english)
        == "José, Person, in 3 memories")
    #expect(
      ReviewCopy.elementLabel(name: "José", type: .person, otherMemories: 1, locale: english)
        == "José, Person, in 1 memory")
  }

  @Test func `A known element announces name, type and its memories in Spanish`() {
    #expect(
      ReviewCopy.elementLabel(name: "el pueblo", type: .place, otherMemories: 3, locale: spanish)
        == "el pueblo, Lugar, en 3 recuerdos")
    #expect(
      ReviewCopy.elementLabel(name: "el pueblo", type: .place, otherMemories: 1, locale: spanish)
        == "el pueblo, Lugar, en 1 recuerdo")
  }

  // F8 contrato 2: el cero, montado, es plural en los dos idiomas
  @Test func `A known element with zero other memories uses the plural, in both languages`() {
    #expect(
      ReviewCopy.elementLabel(name: "José", type: .person, otherMemories: 0, locale: english)
        == "José, Person, in 0 memories")
    #expect(
      ReviewCopy.elementLabel(name: "el pueblo", type: .place, otherMemories: 0, locale: spanish)
        == "el pueblo, Lugar, en 0 recuerdos")
  }

  // sin concordancia de genero (contrato 6): "primera vez", nunca "nuevo"/"nueva"
  @Test func `A new element announces that it is the first time, in both languages`() {
    #expect(
      ReviewCopy.elementLabel(name: "Lucía", type: .person, otherMemories: nil, locale: english)
        == "Lucía, Person, first time")
    #expect(
      ReviewCopy.elementLabel(name: "el reloj", type: .object, otherMemories: nil, locale: spanish)
        == "el reloj, Objeto, primera vez")
  }

  // tokens §1.6: el tachado nunca es la unica señal, VoiceOver lo dice
  @Test func `A removed element announces that it is out of this memory, in both languages`() {
    #expect(
      ReviewCopy.removedElementLabel(name: "José", type: .person, locale: english)
        == "José, Person, removed from this memory")
    #expect(
      ReviewCopy.removedElementLabel(name: "el reloj", type: .object, locale: spanish)
        == "el reloj, Objeto, fuera de este recuerdo")
  }

  // MARK: duda de identidad — la respuesta «no es el mismo» nombra el tipo (DEC-49)

  @Test(arguments: [
    (ElementType.person, "Someone else", "Otra persona"),
    (ElementType.place, "Another place", "Otro lugar"),
    (ElementType.object, "Another object", "Otro objeto"),
  ])
  func `Declining a doubt names the type of what it is, in both languages`(
    type: ElementType, english: String, spanish: String
  ) {
    #expect(ReviewCopy.doubtRejection(type: type, locale: self.english) == english)
    #expect(ReviewCopy.doubtRejection(type: type, locale: self.spanish) == spanish)
  }

  // MARK: el momento de la conexion — su anuncio

  @Test func `The connection moment announces the save and how many memories connect`() {
    #expect(
      ReviewCopy.momentAnnouncement(connectedCount: 1, locale: english)
        == "Memory saved. Connected with 1 memory")
    #expect(
      ReviewCopy.momentAnnouncement(connectedCount: 3, locale: english)
        == "Memory saved. Connected with 3 memories")
    #expect(
      ReviewCopy.momentAnnouncement(connectedCount: 1, locale: spanish)
        == "Recuerdo guardado. Conectado con 1 recuerdo")
    #expect(
      ReviewCopy.momentAnnouncement(connectedCount: 3, locale: spanish)
        == "Recuerdo guardado. Conectado con 3 recuerdos")
  }

  // F8 contrato 2: el momento nunca llega con cero, pero el plural del cero tiene que ser correcto
  @Test func `The connection moment with zero uses the plural, in both languages`() {
    #expect(
      ReviewCopy.momentAnnouncement(connectedCount: 0, locale: english)
        == "Memory saved. Connected with 0 memories")
    #expect(
      ReviewCopy.momentAnnouncement(connectedCount: 0, locale: spanish)
        == "Recuerdo guardado. Conectado con 0 recuerdos")
  }
}
