import Foundation
import Testing

@testable import Hilo

// contrato 1 + contrato 6 + anexo DEC-46: cada error de F3 produce su texto y su estado,
// y solo el generico ofrece reintentar (DEC-42)
nonisolated struct CaptureCopyTests {
  private static let english = Locale(identifier: "en")
  private static let spanish = Locale(identifier: "es")

  private static let genericEN =
    "Hilo couldn't read it this time. It's saved without people, places or objects — you can try again now, or later from the memory."
  private static let genericES =
    "Hilo no ha podido leerlo esta vez. Queda guardado sin personas, lugares ni objetos; puedes volver a intentarlo ahora o más tarde desde el recuerdo."
  private static let overflowEN =
    "This memory is too long for Hilo to read in one go. It's saved without people, places or objects. If you shorten it, you can ask Hilo to read it from the memory."
  private static let overflowES =
    "Este recuerdo es demasiado largo para que Hilo lo lea de una vez. Queda guardado sin personas, lugares ni objetos. Si lo acortas, puedes pedirle que lo lea desde el propio recuerdo."
  private static let languageEN =
    "Hilo can't read memories in this language. It's saved without people, places or objects."
  private static let languageES =
    "Hilo no puede leer recuerdos en este idioma. Queda guardado sin personas, lugares ni objetos."

  struct Expected: Sendable {
    let error: MemoryComprehensionError
    let bodyEN: String
    let bodyES: String
    let actions: ComprehensionNoticeCopy.Actions
  }

  // guardarrail y rechazo comparten el texto generico a proposito: nunca se insinua que
  // el recuerdo sea inapropiado (anexo DEC-46)
  static let expectations: [Expected] = [
    Expected(
      error: .guardrailViolation, bodyEN: genericEN, bodyES: genericES, actions: .retryOrLeave),
    Expected(error: .refusal, bodyEN: genericEN, bodyES: genericES, actions: .retryOrLeave),
    Expected(
      error: .assetsUnavailable, bodyEN: genericEN, bodyES: genericES, actions: .retryOrLeave),
    Expected(error: .decodingFailure, bodyEN: genericEN, bodyES: genericES, actions: .retryOrLeave),
    Expected(error: .noResponse, bodyEN: genericEN, bodyES: genericES, actions: .retryOrLeave),
    Expected(error: .contextOverflow, bodyEN: overflowEN, bodyES: overflowES, actions: .done),
    Expected(error: .unsupportedLanguage, bodyEN: languageEN, bodyES: languageES, actions: .done),
  ]

  @Test(arguments: expectations)
  func `Each F3 error produces its annex text and actions in English`(expected: Expected) {
    let copy = CaptureCopy.comprehensionNotice(
      MemoryComprehensionReason(mapping: expected.error), locale: Self.english)

    #expect(copy.title == "Your memory is saved just as you told it")
    #expect(copy.body == expected.bodyEN)
    #expect(copy.actions == expected.actions)
  }

  @Test(arguments: expectations)
  func `Each F3 error produces its annex text and actions in Spanish`(expected: Expected) {
    let copy = CaptureCopy.comprehensionNotice(
      MemoryComprehensionReason(mapping: expected.error), locale: Self.spanish)

    #expect(copy.title == "Tu recuerdo está guardado tal como lo contaste")
    #expect(copy.body == expected.bodyES)
    #expect(copy.actions == expected.actions)
  }

  // los botones y CaptureState.canRetry leen la misma regla: no pueden divergir
  @Test(arguments: expectations)
  func `The offered actions follow the retry rule`(expected: Expected) {
    let reason = MemoryComprehensionReason(mapping: expected.error)
    #expect(reason.allowsRetry == (expected.actions == .retryOrLeave))
  }

  @Test func `The error announcement reads the title and then the body`() {
    let copy = CaptureCopy.comprehensionNotice(.contextOverflow, locale: Self.spanish)
    #expect(
      copy.announcement == "Tu recuerdo está guardado tal como lo contaste. \(Self.overflowES)")
  }

  // MARK: avisos de la revision y del guardado — un fallo nunca es silencioso (DEC-43)

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

  // MARK: aparicion progresiva — nombre y tipo, igual con Reducir movimiento (contrato 6)

  @Test func `A progressively appearing element announces its name and type in both languages`() {
    #expect(
      CaptureCopy.elementAppeared(name: "José", type: .person, locale: Self.english)
        == "José, Person")
    #expect(
      CaptureCopy.elementAppeared(name: "la casa del pueblo", type: .place, locale: Self.spanish)
        == "la casa del pueblo, Lugar")
  }

  // MARK: anuncio progresivo — cada elemento nuevo se anuncia una vez, aunque lleguen juntos

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
