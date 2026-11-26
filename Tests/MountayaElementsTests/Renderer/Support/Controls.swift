import SwiftUI
import UIKit

/// Controls draws the elements' SwiftUI views a test reads the pixels of, with no window.
public enum Controls {
  /// drawn renders `view` at the screen's density, under the colour scheme `scheme`, or nil where it
  /// draws nothing.
  @MainActor
  public static func drawn(_ view: some View, scheme: ColorScheme = .light) -> UIImage? {
    let renderer = ImageRenderer(content: view.environment(\.colorScheme, scheme))
    renderer.scale = 3
    return renderer.uiImage
  }

  /// color is the pixel a CSS hexadecimal colour, `#rrggbb`, is drawn as, fully opaque.
  public static func color(_ hex: String) -> Pixels.Pixel {
    let digits = Array(hex.dropFirst())
    func channel(_ at: Int) -> Int { Int(String(digits[at..<(at + 2)]), radix: 16) ?? -1 }
    return Pixels.Pixel(red: channel(0), green: channel(2), blue: channel(4), alpha: 255)
  }
}
