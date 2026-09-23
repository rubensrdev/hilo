import Foundation
import Testing

// contrato 5 + criterio F0.1: toda clave del catalogo tiene valor en ingles y en espanol
struct StringCatalogTests {
  private struct Catalog: Codable {
    struct Entry: Codable {
      struct Localization: Codable {
        struct StringUnit: Codable {
          let value: String
        }
        // una clave plural (regla del proyecto: toda cantidad se declara como tal) no trae
        // stringUnit al nivel superior, sino variations.plural.{one,other,...}.stringUnit
        struct Variations: Codable {
          struct Plural: Codable {
            struct Case: Codable {
              let stringUnit: StringUnit
            }
            let one: Case?
            let other: Case?
          }
          let plural: Plural?
        }
        let stringUnit: StringUnit?
        let variations: Variations?

        var value: String? {
          stringUnit?.value ?? variations?.plural?.other?.stringUnit.value
        }
      }
      let localizations: [String: Localization]?
    }
    let strings: [String: Entry]
  }

  private let expectedKeys = [
    "Hilo",
    "Provisional screen — replaced in F4/F5",
    "fondo",
    "superficie-tarjeta",
    "superficie-hundida",
    "superficie-generada",
    "texto-primario",
    "texto-secundario",
    "texto-deshabilitado",
    "acento-hilo",
    "texto-sobre-acento",
    "tipo-persona",
    "tipo-lugar",
    "tipo-objeto",
    "estado-exito",
    "estado-aviso",
    "estado-error",
    "separador",
    // anexo DEC-46 (F4): los textos provisionales entran en los dos idiomas
    "Your memory is saved just as you told it",
    "Hilo couldn't read it this time. It's saved without people, places or objects — you can try again now, or later from the memory.",
    "Try reading it again",
    "Leave it as it is",
    "This memory is too long for Hilo to read in one go. It's saved without people, places or objects. If you shorten it, you can ask Hilo to read it from the memory.",
    "Hilo can't read memories in this language. It's saved without people, places or objects.",
    "Done",
    "These are the first threads",
    "This is the first time %@ appears. The next memory that mentions %@ will connect to this one.",
    "This is the first time %@ appear. The next memory that shares any of them will connect to this one.",
    "No names this time",
    "Hilo didn't find named people, places or objects. It's still a memory, and it will be saved in your words.",
  ]

  // se lee el fichero fuente directamente: el oraculo no puede ser Bundle,
  // porque aqui clave y valor en ingles coinciden y un fallback silencioso pasaria el test
  private func loadCatalog() throws -> Catalog {
    let catalogURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "Hilo/Localizable.xcstrings")
    let data = try Data(contentsOf: catalogURL)
    return try JSONDecoder().decode(Catalog.self, from: data)
  }

  @Test func everyKeyHasEnglishAndSpanishValue() throws {
    let catalog = try loadCatalog()
    for key in expectedKeys {
      let entry = catalog.strings[key]
      #expect(entry != nil, "falta la clave \(key) en el catalogo")
      // ninguna clave trae "en" explicito: por convencion de Xcode, el valor en
      // ingles es la propia clave cuando el idioma base coincide con ella
      if let english = entry?.localizations?["en"]?.value {
        #expect(!english.isEmpty, "el valor en ingles de \(key) esta vacio")
      }
      let spanish = entry?.localizations?["es"]?.value
      #expect(spanish?.isEmpty == false, "falta el valor en espanol de \(key)")
    }
  }
}
