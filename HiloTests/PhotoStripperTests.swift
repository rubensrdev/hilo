import Foundation
import ImageIO
import Testing

@testable import Hilo

struct PhotoStripperTests {
  /// A fixture of its own, independent of project assets: a 2×2 JPEG with real embedded GPS.
  static func jpegWithGPS(width: Int = 2, height: Int = 2) throws -> Data {
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let context = try #require(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
    context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())

    let output = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil))
    let gpsProperties: [CFString: Any] = [
      kCGImagePropertyGPSLatitude: 40.4168,
      kCGImagePropertyGPSLatitudeRef: "N",
      kCGImagePropertyGPSLongitude: 3.7038,
      kCGImagePropertyGPSLongitudeRef: "W",
    ]
    let properties: [CFString: Any] = [kCGImagePropertyGPSDictionary: gpsProperties]
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)
    #expect(CGImageDestinationFinalize(destination))
    return output as Data
  }

  static func gpsDictionary(in data: Data) -> [CFString: Any]? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else { return nil }
    return properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
  }

  @Test func `Stripping metadata from a JPEG with embedded GPS removes the GPS dictionary`()
    throws
  {
    let original = try Self.jpegWithGPS()
    #expect(Self.gpsDictionary(in: original) != nil)

    let stripped = try PhotoStripper.stripMetadata(from: original)

    #expect(Self.gpsDictionary(in: stripped) == nil)
  }

  @Test func `Stripped photo still decodes and keeps the original pixel dimensions`() throws {
    let original = try Self.jpegWithGPS(width: 4, height: 3)

    let stripped = try PhotoStripper.stripMetadata(from: original)

    let source = try #require(CGImageSourceCreateWithData(stripped as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    #expect(image.width == 4)
    #expect(image.height == 3)
  }

  @Test func `Stripping metadata from data that is not an image throws invalidImageData`() {
    let notAnImage = Data("no soy una imagen".utf8)

    #expect(throws: PhotoStripper.StripError.invalidImageData) {
      try PhotoStripper.stripMetadata(from: notAnImage)
    }
  }
}
