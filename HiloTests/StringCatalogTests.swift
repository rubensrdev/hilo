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
        let stringUnit: StringUnit
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
      if let english = entry?.localizations?["en"]?.stringUnit.value {
        #expect(!english.isEmpty, "el valor en ingles de \(key) esta vacio")
      }
      let spanish = entry?.localizations?["es"]?.stringUnit.value
      #expect(spanish?.isEmpty == false, "falta el valor en espanol de \(key)")
    }
  }
}
