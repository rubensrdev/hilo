import Foundation
import Testing

// F8 contrato 2 (criterios 8 y 9): el catalogo entero tiene valor en ingles y español, y toda
// cantidad se declara plural en los dos idiomas — el ingles y el español no coinciden en categorias
struct StringCatalogTests {
  private struct Catalog: Codable {
    struct Entry: Codable {
      struct Localization: Codable {
        struct StringUnit: Codable {
          let value: String
        }
        // una clave plural no trae stringUnit al nivel superior, sino variations.plural.{one,other}
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

        var isPlural: Bool { variations?.plural != nil }

        var values: [String] {
          if let plural = variations?.plural {
            return [plural.one, plural.other].compactMap { $0?.stringUnit.value }
          }
          return [stringUnit?.value].compactMap { $0 }
        }
      }
      let localizations: [String: Localization]?
      let extractionState: String?
    }
    let strings: [String: Entry]
  }

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

  private static let quantityMarkers = ["%lld", "%d", "%ld"]

  private static func hasQuantity(_ key: String) -> Bool {
    quantityMarkers.contains { key.contains($0) }
  }

  @Test func `The catalog is not empty and every key it holds is a real one`() throws {
    let catalog = try loadCatalog()
    #expect(catalog.strings.count > 100)
    #expect(catalog.strings["Settings"] != nil)
    #expect(catalog.strings["in %lld memories"] != nil)
  }

  @Test func `Every key in the catalog has a non-empty Spanish value`() throws {
    let catalog = try loadCatalog()
    for (key, entry) in catalog.strings {
      let spanish = entry.localizations?["es"]
      #expect(spanish != nil, "falta el español de \(key)")
      #expect(
        spanish?.values.allSatisfy { !$0.isEmpty } == true && spanish?.values.isEmpty == false,
        "el español de \(key) esta vacio")
    }
  }

  // por convencion de Xcode el valor en ingles es la propia clave cuando no hay "en" explicito;
  // si lo hay (los plurales), no puede estar vacio
  @Test func `Every explicit English value in the catalog is non-empty`() throws {
    let catalog = try loadCatalog()
    for (key, entry) in catalog.strings {
      guard let english = entry.localizations?["en"] else { continue }
      #expect(
        !english.values.isEmpty && english.values.allSatisfy { !$0.isEmpty },
        "el ingles explicito de \(key) esta vacio")
    }
  }

  @Test func `Every key with a quantity is declared plural in both languages, with one and other`()
    throws
  {
    let catalog = try loadCatalog()
    let quantityKeys = catalog.strings.filter { Self.hasQuantity($0.key) }
    #expect(!quantityKeys.isEmpty)
    for (key, entry) in quantityKeys {
      for language in ["en", "es"] {
        let localization = entry.localizations?[language]
        #expect(localization?.isPlural == true, "\(key) no es plural en \(language)")
        #expect(
          localization?.variations?.plural?.one != nil, "\(key) sin categoria one en \(language)")
        #expect(
          localization?.variations?.plural?.other != nil,
          "\(key) sin categoria other en \(language)")
      }
    }
  }

  // un plural sin cantidad en la clave seria un plural que no puede variar
  @Test func `Every plural key carries a quantity`() throws {
    let catalog = try loadCatalog()
    for (key, entry) in catalog.strings
    where entry.localizations?.values.contains(where: \.isPlural) == true {
      #expect(Self.hasQuantity(key), "\(key) es plural pero no lleva cantidad")
    }
  }

  // las claves obsoletas siguen en el catalogo hasta que Xcode las retire; ninguna nueva de F8
  @Test func `Stale keys are only the provisional screens and the colour names`() throws {
    let catalog = try loadCatalog()
    let stale = catalog.strings.filter { $0.value.extractionState == "stale" }.map(\.key)
    let colourNames: Set<String> = [
      "fondo", "superficie-tarjeta", "superficie-hundida", "superficie-generada",
      "texto-primario", "texto-secundario", "texto-deshabilitado", "acento-hilo",
      "texto-sobre-acento", "tipo-persona", "tipo-lugar", "tipo-objeto", "estado-exito",
      "estado-aviso", "estado-error", "separador",
    ]
    let provisional: Set<String> = [
      "Provisional screen — replaced in F4/F5", "Settings are coming soon",
      "Language and accessibility options will live here.",
    ]
    #expect(Set(stale).isSubset(of: colourNames.union(provisional)), "obsoletas nuevas: \(stale)")
  }
}
