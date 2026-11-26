import Foundation
import Testing

@testable import MountayaElements

#if canImport(ImageIO) && canImport(CoreGraphics)
  import CoreGraphics
  import ImageIO
  import UniformTypeIdentifiers
#endif

@Suite("PlatformElevationDecoder")
struct PlatformElevationDecoderTests {
  @Test("bytes that are no image read no pixels")
  func noImage() {
    #expect(PlatformElevationDecoder().pixels(of: Data("no image".utf8), edge: 2) == nil)
  }

  #if canImport(ImageIO) && canImport(CoreGraphics)
    /// png encodes a square of `edge` pixels each `pixel` as a PNG, through the platform's codec.
    private func png(_ pixel: [UInt8], edge: Int) throws -> Data {
      var rgba = [UInt8]()
      for _ in 0..<(edge * edge) { rgba += pixel + [255] }
      let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
      let provider = try #require(CGDataProvider(data: Data(rgba) as CFData))
      let image = try #require(
        CGImage(
          width: edge, height: edge, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: edge * 4,
          space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
          provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
      let data = NSMutableData()
      let destination = try #require(
        CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
      CGImageDestinationAddImage(destination, image, nil)
      #expect(CGImageDestinationFinalize(destination))
      return data as Data
    }

    @Test("a PNG reads into its channels, its alpha dropped")
    func png() throws {
      let pixels = PlatformElevationDecoder().pixels(of: try png([1, 134, 160], edge: 2), edge: 2)
      #expect(pixels == [1, 134, 160, 1, 134, 160, 1, 134, 160, 1, 134, 160])
    }

    @Test("an image of another edge than the source's reads none")
    func otherEdge() throws {
      #expect(PlatformElevationDecoder().pixels(of: try png([1, 2, 3], edge: 2), edge: 4) == nil)
    }
  #endif
}
