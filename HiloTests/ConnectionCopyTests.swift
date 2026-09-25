import Foundation
import Testing

@testable import Hilo

// regla 4 del diseño + contrato 6: textos de conexion compartidos entre Revision (F4) y Explorar (F5)
nonisolated struct ConnectionCopyTests {
  private let english = Locale(identifier: "en")
  private let spanish = Locale(identifier: "es")

  // MARK: el comienzo — un nombre y varios

  @Test func `One first-time name in English repeats the name`() {
    #expect(
      ConnectionCopy.firstAppearanceBody(names: ["José"], locale: english)
        == "This is the first time José appears. The next memory that mentions José will connect to this one."
    )
  }

  @Test func `One first-time name in Spanish`() {
    #expect(
      ConnectionCopy.firstAppearanceBody(names: ["José"], locale: spanish)
        == "Es la primera vez que aparece José. El próximo recuerdo en el que vuelva a aparecer se conectará con este."
    )
  }

  @Test func `Several first-time names in English join with the English conjunction`() {
    #expect(
      ConnectionCopy.firstAppearanceBody(names: ["José", "el reloj"], locale: english)
        == "This is the first time José and el reloj appear. The next memory that shares any of them will connect to this one."
    )
  }

  // el defecto de F4.5.1: dentro de una frase en ingles la lista salia con "y"
  @Test func `Several first-time names in Spanish join with the Spanish conjunction`() {
    #expect(
      ConnectionCopy.firstAppearanceBody(
        names: ["José", "la casa del pueblo", "el reloj"], locale: spanish)
        == "Es la primera vez que aparecen José, la casa del pueblo y el reloj. El próximo recuerdo en el que vuelva a aparecer cualquiera se conectará con este."
    )
  }

  // MARK: motivo de la conexion — regla 4 del diseño

  @Test func `A connection motive lists its names in the interface language`() {
    #expect(
      ConnectionCopy.connectionMotive(names: ["José", "el reloj"], locale: english)
        == "By José and el reloj")
    #expect(
      ConnectionCopy.connectionMotive(names: ["José", "el reloj"], locale: spanish)
        == "Por José y el reloj")
  }

  // F8 contrato 2: el motivo montado con uno y con varios nombres; con cero no existe conexion
  @Test func `A connection motive with a single name has no conjunction, in both languages`() {
    #expect(ConnectionCopy.connectionMotive(names: ["José"], locale: english) == "By José")
    #expect(ConnectionCopy.connectionMotive(names: ["José"], locale: spanish) == "Por José")
  }

  @Test func `A connection motive with three names lists them in the interface language`() {
    #expect(
      ConnectionCopy.connectionMotive(names: ["José", "el reloj", "Cádiz"], locale: english)
        == "By José, el reloj, and Cádiz")
    #expect(
      ConnectionCopy.connectionMotive(names: ["José", "el reloj", "Cádiz"], locale: spanish)
        == "Por José, el reloj y Cádiz")
  }

  // guia de accesibilidad: una conexion anuncia su motivo antes que el recuerdo, que va entero
  @Test func `A connection row announces its motive first and then the whole memory`() {
    let narrative = "José trajo naranjas del pueblo. Fue el último verano."
    #expect(
      ConnectionCopy.connectionRowLabel(names: ["José"], narrative: narrative, locale: english)
        == "By José. José trajo naranjas del pueblo. Fue el último verano.")
    #expect(
      ConnectionCopy.connectionRowLabel(
        names: ["José", "el pueblo"], narrative: narrative, locale: spanish)
        == "Por José y el pueblo. José trajo naranjas del pueblo. Fue el último verano.")
  }
}
