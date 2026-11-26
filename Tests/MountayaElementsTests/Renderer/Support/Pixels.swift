import UIKit

/// Pixels reads an image a test drew, pixel by pixel, as its colour channels from 0 to 255.
public enum Pixels {
  /// Pixel is one pixel's red, green, blue and alpha, each from 0 to 255, its colour divided out
  /// of its alpha.
  public struct Pixel: Sendable, Equatable, CustomStringConvertible {
    /// red is the pixel's red, from 0 to 255.
    public let red: Int
    /// green is the pixel's green, from 0 to 255.
    public let green: Int
    /// blue is the pixel's blue, from 0 to 255.
    public let blue: Int
    /// alpha is how opaque the pixel is, from 0 to 255.
    public let alpha: Int

    /// Creates a pixel of its four channels.
    public init(red: Int, green: Int, blue: Int, alpha: Int) {
      self.red = red
      self.green = green
      self.blue = blue
      self.alpha = alpha
    }

    /// isNear tells whether every channel is within `tolerance` of `other`'s.
    public func isNear(_ other: Pixel, tolerance: Int = 8) -> Bool {
      abs(red - other.red) <= tolerance && abs(green - other.green) <= tolerance
        && abs(blue - other.blue) <= tolerance && abs(alpha - other.alpha) <= tolerance
    }

    /// description is the pixel as CSS writes a colour.
    public var description: String {
      "rgba(\(red), \(green), \(blue), \(alpha))"
    }
  }

  /// pixel answers the pixel of `image` under the point `point`, in points from its top left
  /// corner, or nil where the image holds no bitmap or the point is outside it.
  public static func pixel(_ image: UIImage, at point: CGPoint) -> Pixel? {
    guard let cgImage = image.cgImage else { return nil }
    let (width, height) = (cgImage.width, cgImage.height)
    let x = Int(point.x * image.scale)
    let y = Int(point.y * image.scale)
    guard x >= 0, y >= 0, x < width, y < height else { return nil }
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
          bytesPerRow: width * 4,
          space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      else { return false }
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard drawn else { return nil }
    let at = (y * width + x) * 4
    let alpha = Int(bytes[at + 3])
    func channel(_ value: UInt8) -> Int {
      alpha == 0 ? 0 : min(255, Int((Double(value) * 255 / Double(alpha)).rounded()))
    }
    return Pixel(
      red: channel(bytes[at]), green: channel(bytes[at + 1]), blue: channel(bytes[at + 2]),
      alpha: alpha)
  }
}
