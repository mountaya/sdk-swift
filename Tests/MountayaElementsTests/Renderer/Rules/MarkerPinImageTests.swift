import MountayaGeo
import RendererSupport
import Testing
import UIKit

@testable import MountayaElements

@Suite("markerPinImage")
@MainActor
struct MarkerPinImageTests {
  private static let white = Pixels.Pixel(red: 255, green: 255, blue: 255, alpha: 255)
  private static let accent = Pixels.Pixel(red: 0x1c, green: 0x7e, blue: 0xd6, alpha: 255)
  private static let red = Pixels.Pixel(red: 0xe0, green: 0x31, blue: 0x31, alpha: 255)

  /// block is a set whose one glyph fills its whole box, which shows where a glyph is drawn.
  private static func block() throws -> GlyphSet {
    try #require(
      GlyphSet(name: "block", paint: .fill, markup: ["block": #"<rect width="24" height="24"/>"#]))
  }

  /// pin draws the pin of a marker in `color` naming `glyph`, of `set`, on the map's accent.
  private static func pin(color: String?, glyph: String?, in set: GlyphSet) -> UIImage {
    markerPinImage(
      describeMarkerPin(color: color, glyph: glyph, in: set), accent: HexColor(hex: "#1c7ed6"),
      in: set)
  }

  @Test("a pin is 28 points square at the screen's density, a colour image never recoloured")
  func size() {
    let image = Self.pin(color: nil, glyph: nil, in: .marker)

    #expect(image.size == CGSize(width: 28, height: 28))
    #expect(image.scale >= 1)
    #expect(image.renderingMode == .alwaysOriginal)
    #expect(image.cgImage?.width == Int((28 * image.scale).rounded()))
  }

  @Test("a pin naming no colour is the accent inside its white ring, a white dot at its centre")
  func accentAndDot() {
    let image = Self.pin(color: nil, glyph: nil, in: .marker)

    // The ring's middle, a point and a half in from the edge: white.
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 1.5))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 26.5, y: 14))?.isNear(Self.white) == true)
    // Inside the ring, outside the dot 8 points across: the accent.
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 6))?.isNear(Self.accent) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 8, y: 14))?.isNear(Self.accent) == true)
    // The dot.
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
    // A corner, outside the disc: nothing.
    #expect(Pixels.pixel(image, at: CGPoint(x: 0.5, y: 0.5))?.alpha == 0)
    #expect(Pixels.pixel(image, at: CGPoint(x: 27.5, y: 27.5))?.alpha == 0)
  }

  @Test("a colour fills the disc, and a glyph the set draws stands white in the 16-point square")
  func glyph() throws {
    let set = try Self.block()
    let image = Self.pin(color: "#e03131", glyph: "block", in: set)

    // The glyph fills its square, from 6 to 22 on each axis, whatever its set's grid.
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 7, y: 7))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 21, y: 21))?.isNear(Self.white) == true)
    // Between the ring and the square: the marker's colour.
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 4.5))?.isNear(Self.red) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 4.5, y: 14))?.isNear(Self.red) == true)
  }

  @Test("a glyph the set cannot draw gives way to the dot, in the marker's colour")
  func missingGlyph() {
    let image = Self.pin(color: "#e03131", glyph: "no-such-glyph", in: .marker)

    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 8))?.isNear(Self.red) == true)
  }

  @Test("a fill that is no colour fills no disc, its ring and its centre drawn all the same")
  func unreadableFill() {
    let image = Self.pin(color: "crimson", glyph: nil, in: .marker)

    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 6))?.alpha == 0)
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 1.5))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
  }
}
