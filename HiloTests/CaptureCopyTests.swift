import Foundation
import Testing

@testable import Hilo

nonisolated struct CaptureCopyTests {
  private static let english = Locale(identifier: "en")
  private static let spanish = Locale(identifier: "es")

  // MARK: review and save notices — a failure is never silent

  @Test func `Each review notice has its text in both languages`() {
    #expect(
      CaptureCopy.notice(.reviewUnavailable, locale: Self.english)
        == "Hilo couldn't open the review. Your memory is still here — you can try again.")
    #expect(
      CaptureCopy.notice(.reviewUnavailable, locale: Self.spanish)
        == "Hilo no ha podido abrir la revisión. Tu recuerdo sigue aquí; puedes volver a intentarlo."
    )
    #expect(
      CaptureCopy.notice(.reviewNotSaved, locale: Self.english)
        == "Hilo couldn't save the review. Your memory is still here — you can try again.")
    #expect(
      CaptureCopy.notice(.reviewNotSaved, locale: Self.spanish)
        == "Hilo no ha podido guardar la revisión. Tu recuerdo sigue aquí; puedes volver a intentarlo."
    )
    #expect(CaptureCopy.notice(.savedWithoutAnalyzing, locale: Self.english) == "Memory saved")
    #expect(CaptureCopy.notice(.savedWithoutAnalyzing, locale: Self.spanish) == "Recuerdo guardado")
  }

  // MARK: progressive appearance — name and type, the same with Reduce Motion

  @Test func `A progressively appearing element announces its name and type in both languages`() {
    #expect(
      CaptureCopy.elementAppeared(name: "José", type: .person, locale: Self.english)
        == "José, Person")
    #expect(
      CaptureCopy.elementAppeared(name: "la casa del pueblo", type: .place, locale: Self.spanish)
        == "la casa del pueblo, Lugar")
  }

  // MARK: progressive announcement — each new element once, even when they arrive together

  @Test func `Two elements arriving in the same snapshot are both announced, in English`() {
    let current = [
      ExtractedElement(name: "José", type: .person, role: "mi abuelo"),
      ExtractedElement(name: "Cádiz", type: .place, role: "el destino"),
    ]

    #expect(
      CaptureCopy.elementsAppeared(current, after: [], locale: Self.english)
        == "José, Person and Cádiz, Place")
  }

  @Test func `Two elements arriving in the same snapshot are both announced, in Spanish`() {
    let current = [
      ExtractedElement(name: "José", type: .person, role: "mi abuelo"),
      ExtractedElement(name: "el reloj", type: .object, role: "el regalo"),
    ]

    #expect(
      CaptureCopy.elementsAppeared(current, after: [], locale: Self.spanish)
        == "José, Persona y el reloj, Objeto")
  }

  @Test func `Only the element that is new in this snapshot is announced`() {
    let current = [
      ExtractedElement(name: "José", type: .person, role: "mi abuelo"),
      ExtractedElement(name: "Cádiz", type: .place, role: "el destino"),
    ]

    #expect(
      CaptureCopy.elementsAppeared(current, after: ["José"], locale: Self.english)
        == "Cádiz, Place")
  }

  @Test func `A snapshot that loses an element announces nothing again`() {
    let current = [ExtractedElement(name: "José", type: .person, role: "mi abuelo")]

    #expect(
      CaptureCopy.elementsAppeared(current, after: ["José", "Cádiz"], locale: Self.english) == nil)
  }
}
