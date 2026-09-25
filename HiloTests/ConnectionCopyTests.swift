import Foundation
import Testing

@testable import Hilo

nonisolated struct ConnectionCopyTests {
  private let english = Locale(identifier: "en")
  private let spanish = Locale(identifier: "es")

  // MARK: the beginning — one name and several

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

  /// Regression: inside an English sentence the list came out joined with "y".
  @Test func `Several first-time names in Spanish join with the Spanish conjunction`() {
    #expect(
      ConnectionCopy.firstAppearanceBody(
        names: ["José", "la casa del pueblo", "el reloj"], locale: spanish)
        == "Es la primera vez que aparecen José, la casa del pueblo y el reloj. El próximo recuerdo en el que vuelva a aparecer cualquiera se conectará con este."
    )
  }

  // MARK: connection motive

  @Test func `A connection motive lists its names in the interface language`() {
    #expect(
      ConnectionCopy.connectionMotive(names: ["José", "el reloj"], locale: english)
        == "By José and el reloj")
    #expect(
      ConnectionCopy.connectionMotive(names: ["José", "el reloj"], locale: spanish)
        == "Por José y el reloj")
  }

  /// Composed with one name and with several; with none there is no connection.
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
