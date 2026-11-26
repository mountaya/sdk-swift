import MountayaGeo
import SwiftUI
import Testing
import UIKit

@testable import MountayaElements

@Suite("tokenColor")
@MainActor
struct TokenColorTests {
  /// channels reads a colour's red, green, blue and alpha, from 0 to 255.
  private static func channels(_ color: Color) -> [Int] {
    var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
    UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
  }

  @Test("a token reads its light value under the light scheme and its dark one under the dark")
  func schemes() {
    let standard = ElementTokens.standard

    #expect(Self.channels(tokenColor(standard.controlBg, in: .light)) == [255, 255, 255, 255])
    #expect(Self.channels(tokenColor(standard.controlBg, in: .dark)) == [0x25, 0x26, 0x2b, 255])
    #expect(Self.channels(tokenColor(standard.accent, in: .dark)) == [0x1c, 0x7e, 0xd6, 255])
    #expect(
      Self.channels(tokenColor(standard.profileNavigatorVeil, in: .dark)) == [0, 0, 0, 140])
  }

  @Test("a consumer's value stands in both schemes, and one that is no colour is clear")
  func consumer() {
    let translucent = ThemeToken(light: HexColor(hex: "#000000", opacity: 0.8))

    #expect(Self.channels(tokenColor(translucent, in: .dark)) == [0, 0, 0, 204])
    #expect(Self.channels(tokenColor(ThemeToken(light: HexColor(hex: "teal")), in: .light))[3] == 0)
  }

  @Test("SwiftUI's dark scheme draws the dark tokens, and every other scheme the light")
  func swiftUiScheme() {
    #expect(themeScheme(.dark) == .dark)
    #expect(themeScheme(.light) == .light)
  }
}
