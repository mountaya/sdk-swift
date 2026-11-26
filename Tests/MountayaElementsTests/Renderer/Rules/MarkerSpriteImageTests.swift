import MountayaGeo
import RendererSupport
import Testing
import UIKit

@testable import MountayaElements

@Suite("markerSpriteImage")
@MainActor
struct MarkerSpriteImageTests {
  private static let white = Pixels.Pixel(red: 255, green: 255, blue: 255, alpha: 255)
  private static let red = Pixels.Pixel(red: 224, green: 49, blue: 49, alpha: 255)

  /// sprite draws the sprite of `glyph` of `set` in `color`.
  private static func sprite(_ glyph: String, color: String, in set: GlyphSet) throws -> UIImage {
    let described = try #require(describeMarkerSprite(glyph, color: color, in: set))
    return markerSpriteImage(described, figures: try #require(glyphFigures(glyph, in: set)))
  }

  @Test("a sprite is 48 points square at the screen's density, a colour image never recoloured")
  func size() throws {
    let image = try Self.sprite("hut", color: "#e03131", in: .marker)

    #expect(image.size == CGSize(width: 48, height: 48))
    #expect(image.scale >= 1)
    #expect(image.renderingMode == .alwaysOriginal)
    #expect(image.cgImage?.width == Int((48 * image.scale).rounded()))
  }

  @Test("the disc is the feature's colour under a white border, the corners left clear")
  func disc() throws {
    let image = try Self.sprite("hut", color: "#e03131", in: .marker)

    // Inside the disc, above the glyph's square: the feature's colour.
    #expect(Pixels.pixel(image, at: CGPoint(x: 24, y: 8))?.isNear(Self.red) == true)
    // The border's middle, 21 points from the centre: white.
    #expect(Pixels.pixel(image, at: CGPoint(x: 24, y: 3))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 45, y: 24))?.isNear(Self.white) == true)
    // A corner, outside the disc and its border: nothing.
    #expect(Pixels.pixel(image, at: CGPoint(x: 1, y: 1))?.alpha == 0)
    #expect(Pixels.pixel(image, at: CGPoint(x: 47, y: 47))?.alpha == 0)
  }

  @Test("the glyph is white, fitted to the 24-point square at the centre whatever its set's grid")
  func glyph() throws {
    // A glyph filling its whole box shows where the square is drawn.
    let block = #"<rect width="48" height="48"/>"#
    let grid48 = try #require(
      GlyphSet(name: "grid48", paint: .fill, viewBox: 48, markup: ["block": block]))
    let image = try Self.sprite("block", color: "#e03131", in: grid48)

    #expect(Pixels.pixel(image, at: CGPoint(x: 13, y: 13))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 34.5, y: 34.5))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 11, y: 24))?.isNear(Self.red) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 37, y: 24))?.isNear(Self.red) == true)
  }

  @Test("a stroke is drawn at the set's width scaled with the glyph, with its round ends")
  func stroke() throws {
    // A line across the middle of a 24-unit box, 2 units wide: 2 points in the sprite.
    let line = try #require(
      GlyphSet(name: "line", paint: .stroke, markup: ["line": #"<path d="M4 12h16"/>"#]))
    let image = try Self.sprite("line", color: "#e03131", in: line)

    #expect(Pixels.pixel(image, at: CGPoint(x: 24, y: 24))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 24, y: 26.5))?.isNear(Self.red) == true)
    // The round cap reaches a unit past the line's end.
    #expect(Pixels.pixel(image, at: CGPoint(x: 31.5, y: 24))?.isNear(Self.white) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 33.5, y: 24))?.isNear(Self.red) == true)
  }

  @Test("a colour that is no colour fills no disc, and the border and glyph are still drawn")
  func noColour() throws {
    let image = try Self.sprite("hut", color: "teal", in: .marker)

    #expect(Pixels.pixel(image, at: CGPoint(x: 24, y: 8))?.alpha == 0)
    #expect(Pixels.pixel(image, at: CGPoint(x: 24, y: 3))?.isNear(Self.white) == true)
  }
}
