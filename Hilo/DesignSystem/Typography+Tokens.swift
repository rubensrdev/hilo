import SwiftUI

/// New York only for the three roles that carry the user's own words. tokens.md asks the
/// narrative for generous leading without giving a value, so no lineSpacing is set.
extension View {
  func tituloPantalla() -> some View {
    font(.largeTitle)
  }

  func tituloSeccion() -> some View {
    font(.title3.weight(.semibold))
  }

  func encabezadoEpoca() -> some View {
    font(.headline.weight(.semibold))
  }

  func relato() -> some View {
    font(.body)
      .fontDesign(.serif)
  }

  func relatoExtracto() -> some View {
    font(.body)
      .fontDesign(.serif)
  }

  func fechaUsuario() -> some View {
    font(.subheadline)
      .fontDesign(.serif)
      .italic()
  }

  func nombreElemento() -> some View {
    font(.headline.weight(.semibold))
  }

  func chipElemento() -> some View {
    font(.subheadline.weight(.medium))
  }

  func metadato() -> some View {
    font(.footnote)
  }

  func motivoConexion() -> some View {
    font(.footnote)
  }

  func textoGenerado() -> some View {
    font(.body)
  }

  func etiquetaFuentes() -> some View {
    font(.footnote.weight(.semibold))
  }

  func avisoFueraTope() -> some View {
    font(.footnote)
  }

  func reconocimientoHonesto() -> some View {
    font(.title3)
  }

  func preguntaIdentidad() -> some View {
    font(.headline)
  }

  func hebraSuelta() -> some View {
    font(.callout)
  }

  func botonPrincipal() -> some View {
    font(.headline.weight(.semibold))
  }

  func botonSecundario() -> some View {
    font(.body)
  }
}
