import Foundation
import ImageIO

// contrato 3 + DEC-27: se guardan los pixeles, nunca los metadatos ni la ubicacion
enum PhotoStripper {
  enum StripError: Error, Equatable {
    case invalidImageData
  }

  // puro, sin UI: se llama desde el actor de persistencia sin cruzar a MainActor
  nonisolated static func stripMetadata(from data: Data) throws -> Data {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let type = CGImageSourceGetType(source),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      throw StripError.invalidImageData
    }
    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(output, type, 1, nil) else {
      throw StripError.invalidImageData
    }
    // properties: nil => ninguna propiedad (EXIF/GPS/orientacion) pasa al destino
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw StripError.invalidImageData
    }
    return output as Data
  }
}
