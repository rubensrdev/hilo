import Foundation
import Testing

@testable import Hilo

// contrato 5 + DEC-49: el momento de la conexion, solo cuando el recuerdo guardado conecta con algo
nonisolated struct ConnectionMomentTests {
  @Test
  func `A memory sharing José with another shows one row with that narrative and José as motive`()
    throws
  {
    let earlier = try #require(
      Memory(narrative: "José trajo naranjas del huerto.", savedAt: Date()))
    let saved = try #require(Memory(narrative: "Una tarde de dominó con José.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))

    let moment = try #require(
      ConnectionMoment(
        savedMemoryID: saved.id, memories: [earlier, saved], elements: [jose],
        appearances: [
          Appearance(memoryID: earlier.id, elementID: jose.id, role: nil, status: .confirmedByUser),
          Appearance(memoryID: saved.id, elementID: jose.id, role: nil, status: .confirmedByUser),
        ]))

    #expect(moment.narrative == "Una tarde de dominó con José.")
    #expect(
      moment.rows == [
        ConnectionMoment.Row(
          memoryID: earlier.id, narrative: "José trajo naranjas del huerto.",
          motiveNames: ["José"])
      ])
  }

  @Test
  func
    `Two shared elements with one memory give one row with both motives in the saved memory's order`()
    throws
  {
    let earlier = try #require(
      Memory(narrative: "José me enseñó fotos de Granada.", savedAt: Date()))
    let saved = try #require(
      Memory(narrative: "Granada, 1994. Se perdió José en los jardines.", savedAt: Date()))
    let jose = try #require(Element(displayName: "José", type: .person))
    let granada = try #require(Element(displayName: "Granada", type: .place))

    let moment = try #require(
      ConnectionMoment(
        savedMemoryID: saved.id, memories: [earlier, saved], elements: [jose, granada],
        appearances: [
          Appearance(memoryID: earlier.id, elementID: jose.id, role: nil, status: .confirmedByUser),
          Appearance(
            memoryID: earlier.id, elementID: granada.id, role: nil, status: .confirmedByUser),
          Appearance(
            memoryID: saved.id, elementID: granada.id, role: nil, status: .confirmedByUser),
          Appearance(memoryID: saved.id, elementID: jose.id, role: nil, status: .confirmedByUser),
        ]))

    #expect(moment.rows.map(\.motiveNames) == [["Granada", "José"]])
  }

  @Test func `A saved memory with no appearances has no connection moment`() throws {
    let earlier = try #require(Memory(narrative: "El reloj del abuelo.", savedAt: Date()))
    let saved = try #require(Memory(narrative: "Una tarde sin nombres.", savedAt: Date()))
    let reloj = try #require(Element(displayName: "el reloj", type: .object))

    let moment = ConnectionMoment(
      savedMemoryID: saved.id, memories: [earlier, saved], elements: [reloj],
      appearances: [
        Appearance(memoryID: earlier.id, elementID: reloj.id, role: nil, status: .confirmedByUser)
      ])

    #expect(moment == nil)
  }

  @Test func `A first memory whose elements appear nowhere else has no connection moment`() throws {
    let saved = try #require(Memory(narrative: "Lucía aprendió a montar en bici.", savedAt: Date()))
    let lucia = try #require(Element(displayName: "Lucía", type: .person))

    let moment = ConnectionMoment(
      savedMemoryID: saved.id, memories: [saved], elements: [lucia],
      appearances: [
        Appearance(memoryID: saved.id, elementID: lucia.id, role: nil, status: .confirmedByUser)
      ])

    #expect(moment == nil)
  }

  @Test func `The motive uses the element's display name, never one of its aliases`() throws {
    let earlier = try #require(Memory(narrative: "El abuelo nos llevó al río.", savedAt: Date()))
    let saved = try #require(Memory(narrative: "El abuelo arreglaba la radio.", savedAt: Date()))
    let abuelo = Element(
      id: ElementID(), displayName: "abuelo Ramón", type: .person, aliases: ["el abuelo"])

    let moment = try #require(
      ConnectionMoment(
        savedMemoryID: saved.id, memories: [earlier, saved], elements: [abuelo],
        appearances: [
          Appearance(
            memoryID: earlier.id, elementID: abuelo.id, role: nil, status: .confirmedByUser),
          Appearance(memoryID: saved.id, elementID: abuelo.id, role: nil, status: .confirmedByUser),
        ]))

    #expect(moment.rows.first?.motiveNames == ["abuelo Ramón"])
  }

  @Test func `A connection whose shared element cannot be named is left out, and with none left there is no moment`()
    throws
  {
    let earlier = try #require(Memory(narrative: "José trajo naranjas.", savedAt: Date()))
    let saved = try #require(Memory(narrative: "José y el dominó.", savedAt: Date()))
    let unnamed = ElementID()

    let moment = ConnectionMoment(
      savedMemoryID: saved.id, memories: [earlier, saved], elements: [],
      appearances: [
        Appearance(memoryID: earlier.id, elementID: unnamed, role: nil, status: .confirmedByUser),
        Appearance(memoryID: saved.id, elementID: unnamed, role: nil, status: .confirmedByUser),
      ])

    #expect(moment == nil)
  }

  @Test func `The date is the user's text, and a memory without a date has none`() throws {
    let jose = try #require(Element(displayName: "José", type: .person))
    let earlier = try #require(Memory(narrative: "José y el reloj.", savedAt: Date()))
    let dated = try #require(
      Memory(
        narrative: "José me regaló el reloj.",
        date: MemoryDate(text: "el verano del 87", deducedYear: 1987), savedAt: Date()))
    let undated = try #require(Memory(narrative: "José silbaba en la cocina.", savedAt: Date()))
    let appearances = [earlier, dated, undated].map {
      Appearance(memoryID: $0.id, elementID: jose.id, role: nil, status: .confirmedByUser)
    }

    let datedMoment = try #require(
      ConnectionMoment(
        savedMemoryID: dated.id, memories: [earlier, dated, undated], elements: [jose],
        appearances: appearances))
    let undatedMoment = try #require(
      ConnectionMoment(
        savedMemoryID: undated.id, memories: [earlier, dated, undated], elements: [jose],
        appearances: appearances))

    #expect(datedMoment.dateText == "el verano del 87")
    #expect(undatedMoment.dateText == nil)
  }
}
