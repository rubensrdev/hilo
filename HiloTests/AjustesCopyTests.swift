import Foundation
import Testing

@testable import Hilo

// F8 contrato 1: la version y los dos pasos del borrado total, en los dos idiomas
nonisolated struct AjustesCopyTests {
  private static let english = Locale(identifier: "en")
  private static let spanish = Locale(identifier: "es")

  @Test func `The version line names the product version, in both languages`() {
    #expect(AjustesCopy.versionLine("1.0", locale: Self.english) == "Version 1.0")
    #expect(AjustesCopy.versionLine("1.0", locale: Self.spanish) == "Versión 1.0")
  }

  // el texto dice exactamente que desaparece: recuerdos, personas/lugares/objetos y fotos
  @Test func `The first wipe step says exactly what disappears, in both languages`() {
    #expect(
      AjustesCopy.wipeFirstStepBody(locale: Self.english)
        == "Every memory, every person, place and object, and every photo will be deleted from this iPhone. Hilo will start again as on the first day."
    )
    #expect(
      AjustesCopy.wipeFirstStepBody(locale: Self.spanish)
        == "Se borrarán todos los recuerdos, todas las personas, lugares y objetos, y todas las fotos de este iPhone. Hilo volverá a empezar como el primer día."
    )
  }

  @Test func `The second wipe step states that it cannot be undone, in both languages`() {
    #expect(
      AjustesCopy.wipeSecondStepBody(locale: Self.english)
        == "This cannot be undone. There is no copy anywhere else.")
    #expect(
      AjustesCopy.wipeSecondStepBody(locale: Self.spanish)
        == "No se puede deshacer. No hay copia en ningún otro sitio.")
  }

  @Test func `The product version is read from the bundle info, empty when absent`() {
    #expect(ProductVersion.read(from: ["CFBundleShortVersionString": "1.0"]) == "1.0")
    #expect(ProductVersion.read(from: [:]) == "")
  }
}
