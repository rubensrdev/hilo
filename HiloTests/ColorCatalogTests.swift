import Testing
import UIKit

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
    ]

    @Test func everyTokenNameExistsInTheCatalog() {
        for name in expectedNames {
            #expect(UIColor(named: name) != nil, "falta el colorset \(name)")
        }
    }
}
