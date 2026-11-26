import Foundation
import Testing

@testable import MountayaElements

@Suite("ElevationImageDecoding")
struct ElevationImageDecodingTests {
  /// Bytes reads an image as the bytes it holds, three to a pixel.
  private struct Bytes: ElevationImageDecoding {
    func pixels(of image: Data, edge: Int) -> [UInt8]? {
      image.count == edge * edge * 3 ? Array(image) : nil
    }
  }

  @Test("a decoder answers an image's red, green and blue bytes, or none for another edge")
  func pixels() {
    let decoder: any ElevationImageDecoding = Bytes()
    #expect(decoder.pixels(of: Data([1, 134, 160]), edge: 1) == [1, 134, 160])
    #expect(decoder.pixels(of: Data([1, 134, 160]), edge: 2) == nil)
  }
}
