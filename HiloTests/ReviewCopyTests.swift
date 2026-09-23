import Foundation
import Testing

@testable import Hilo

// contrato 6 + anexo DEC-46: textos compuestos de la revision y del momento, en los dos idiomas
nonisolated struct ReviewCopyTests {
  private let english = Locale(identifier: "en")
  private let spanish = Locale(identifier: "es")

  // MARK: el comienzo — un nombre y varios

  @Test func `One first-time name in English repeats the name`() {
    #expect(
      ReviewCopy.beginningBody(names: ["José"], locale: english)
        == "This is the first time José appears. The next memory that mentions José will connect to this one."
    )
  }

  @Test func `One first-time name in Spanish`() {
    #expect(
      ReviewCopy.beginningBody(names: ["José"], locale: spanish)
        == "Es la primera vez que aparece José. El próximo recuerdo en el que vuelva a aparecer se conectará con este."
    )
  }

  @Test func `Several first-time names in English join with the English conjunction`() {
    #expect(
      ReviewCopy.beginningBody(names: ["José", "el reloj"], locale: english)
        == "This is the first time José and el reloj appear. The next memory that shares any of them will connect to this one."
    )
  }

  // el defecto de F4.5.1: dentro de una frase en ingles la lista salia con "y"
  @Test func `Several first-time names in Spanish join with the Spanish conjunction`() {
    #expect(
      ReviewCopy.beginningBody(names: ["José", "la casa del pueblo", "el reloj"], locale: spanish)
        == "Es la primera vez que aparecen José, la casa del pueblo y el reloj. El próximo recuerdo que comparta cualquiera de ellos se conectará con este."
    )
  }

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

  // MARK: el momento de la conexion — su motivo y su anuncio

  @Test func `A connection motive lists its names in the interface language`() {
    #expect(
      ReviewCopy.connectionMotive(names: ["José", "el reloj"], locale: english)
        == "By José and el reloj")
    #expect(
      ReviewCopy.connectionMotive(names: ["José", "el reloj"], locale: spanish)
        == "Por José y el reloj")
  }

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
}
