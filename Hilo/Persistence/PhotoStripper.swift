import Foundation
import ImageIO

/// Keeps the pixels, never the metadata or the location.
enum PhotoStripper {
  enum StripError: Error, Equatable {
    case invalidImageData
  }

  /// Pure and UI-free: the persistence actor calls it without hopping to the main actor.
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
    // nil properties: no EXIF, GPS or orientation reaches the destination.
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw StripError.invalidImageData
    }
    return output as Data
  }
}
