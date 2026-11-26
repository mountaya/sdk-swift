import Foundation

#if canImport(ImageIO) && canImport(CoreGraphics)
  import CoreGraphics
  import ImageIO
#endif

/// PlatformElevationDecoder reads an elevation tile's image through the platform's own codec,
/// ImageIO and Core Graphics on Apple's platforms, which read WebP and PNG alike, with no
/// dependency of its own. The image is drawn into an sRGB bitmap of its own edge with no
/// interpolation, so each pixel's channels are the ones the image holds, and its alpha, which no
/// encoding reads, is dropped.
///
/// A platform with no image codec of its own, Linux among them, reads none, so a map there states
/// no terrain in its readout.
struct PlatformElevationDecoder: ElevationImageDecoding {
  func pixels(of image: Data, edge: Int) -> [UInt8]? {
    #if canImport(ImageIO) && canImport(CoreGraphics)
      guard edge > 0, let source = CGImageSourceCreateWithData(image as CFData, nil),
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil),
        decoded.width == edge, decoded.height == edge,
        let space = CGColorSpace(name: CGColorSpace.sRGB)
      else { return nil }
      var rgba = [UInt8](repeating: 0, count: edge * edge * 4)
      let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
        guard
          let context = CGContext(
            data: buffer.baseAddress, width: edge, height: edge, bitsPerComponent: 8,
            bytesPerRow: edge * 4, space: space,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return false }
        context.interpolationQuality = .none
        context.draw(decoded, in: CGRect(x: 0, y: 0, width: edge, height: edge))
        return true
      }
      guard drawn else { return nil }
      var rgb = [UInt8](repeating: 0, count: edge * edge * 3)
      for pixel in 0..<(edge * edge) {
        rgb[pixel * 3] = rgba[pixel * 4]
        rgb[pixel * 3 + 1] = rgba[pixel * 4 + 1]
        rgb[pixel * 3 + 2] = rgba[pixel * 4 + 2]
      }
      return rgb
    #else
      return nil
    #endif
  }
}
