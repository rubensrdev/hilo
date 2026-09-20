import SwiftUI

// contrato 4: roles tipograficos de tokens.md §2, cada uno fija su text style
// del sistema; New York solo en las tres entradas de §2.1 "palabras del usuario"
// relato: tokens.md pide "interlineado amplio" sin dar un valor numerico exacto,
// a diferencia del resto del documento — sin token no hay lineSpacing que poner
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
