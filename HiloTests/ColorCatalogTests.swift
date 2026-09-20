import Foundation
import Testing

// contrato 3: la lista de nombres esperados vive aqui, no en produccion
struct ColorCatalogTests {
  private let expectedNames = [
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
    "borde-tarjeta",
    "borde-chip-nuevo",
  ]

  // se lee el colorset del disco en vez de UIColor(named:): SwiftUI only, sin UIKit
  private func colorsetURL(for name: String) -> URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "Hilo/Assets.xcassets/\(name).colorset/Contents.json")
  }

  @Test func everyTokenNameExistsInTheCatalog() {
    for name in expectedNames {
      let exists = FileManager.default.fileExists(atPath: colorsetURL(for: name).path)
      #expect(exists, "falta el colorset \(name)")
    }
  }
}
