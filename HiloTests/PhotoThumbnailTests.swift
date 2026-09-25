import Foundation
import ImageIO
import Testing

@testable import Hilo

/// The capture thumbnail decodes with ImageIO, never with UIKit (ADR-000 §4).
struct PhotoThumbnailTests {
  static func jpeg(width: Int, height: Int, orientation: Int = 1) throws -> Data {
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let context = try #require(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
    context.setFillColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())

    let output = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil))
    let properties: [CFString: Any] = [kCGImagePropertyOrientation: orientation]
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)
    #expect(CGImageDestinationFinalize(destination))
    return output as Data
  }

  @Test func `Data that is not an image gives no thumbnail`() {
    #expect(PhotoThumbnail.image(from: Data("no es una imagen".utf8), maxPixelSize: 300) == nil)
  }

  @Test func `A large photo is scaled down to the maximum size keeping its proportion`() throws {
    let data = try Self.jpeg(width: 600, height: 400)

    let thumbnail = try #require(PhotoThumbnail.image(from: data, maxPixelSize: 300))

    #expect(thumbnail.width == 300)
    #expect(thumbnail.height == 200)
  }

  /// As UIImage did: a photo taken upright shows upright.
  @Test func `The orientation stored in the photo is applied to the thumbnail`() throws {
    let data = try Self.jpeg(width: 600, height: 400, orientation: 6)

    let thumbnail = try #require(PhotoThumbnail.image(from: data, maxPixelSize: 300))

    #expect(thumbnail.width == 200)
    #expect(thumbnail.height == 300)
  }
}
