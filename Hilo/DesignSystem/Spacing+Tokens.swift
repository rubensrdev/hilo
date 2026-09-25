import SwiftUI

// contrato 4: escala de espaciado, densidad, radios y trazos de tokens.md §3
// trazo-vinculo no entra: es una funcion de recuento de recuerdos (dominio del
// tejido, F9), no un valor — meterla aqui seria logica en DesignSystem
enum Spacing {
  static let espacio1: CGFloat = 4
  static let espacio2: CGFloat = 8
  static let espacio3: CGFloat = 12
  static let espacio4: CGFloat = 16
  static let espacio5: CGFloat = 24
  static let espacio6: CGFloat = 32
  static let espacio7: CGFloat = 48

  static let margenPantalla = espacio4
  static let rellenoTarjeta = espacio4
  static let separacionTarjetas = espacio3
  static let separacionSecciones = espacio5
  static let separacionChips = espacio2
  static let altoFilaMinimo: CGFloat = 44
  static let objetivoToqueMinimo: CGFloat = 44
  // el campo crece con el texto, por eso el minimo no escala con Dynamic Type
  static let altoMinimoCampoCaptura: CGFloat = 160

  // radio-tarjeta, radio-campo y radio-foto son "continuo": la vista aplica
  // RoundedRectangle(cornerRadius:, style: .continuous), el valor no lo dice
  static let radioTarjeta: CGFloat = 16
  static let radioCampo: CGFloat = 12
  static let radioFoto: CGFloat = 12
  static let radioChip = Capsule()

  // foto-tarjeta (tokens.md §1.9): ancho entre alto
  static let proporcionFotoTarjeta: CGFloat = 3 / 2
  static let altoFotoCaptura: CGFloat = 120

  static let trazoBordeTarjeta: CGFloat = 1
  static let trazoChipConocido: CGFloat = 1.5
  static let trazoConexion: CGFloat = 2.5
}

// trazo-separador es 1 pixel fisico, no 1 punto: depende de la escala de pantalla
private struct TrazoSeparador: ViewModifier {
  @Environment(\.displayScale) private var displayScale

  func body(content: Content) -> some View {
    content.frame(height: 1 / displayScale)
  }
}

extension View {
  func trazoSeparador() -> some View {
    modifier(TrazoSeparador())
  }

  // tokens §1.5: el trazo se dibuja siempre y el colorset (transparente salvo en alto contraste) decide;
  // no se llama bordeTarjeta() porque Color es View y taparia a Color.bordeTarjeta
  func contornoTarjeta() -> some View {
    overlay {
      RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous)
        .strokeBorder(Color.bordeTarjeta, lineWidth: Spacing.trazoBordeTarjeta)
    }
  }
}
