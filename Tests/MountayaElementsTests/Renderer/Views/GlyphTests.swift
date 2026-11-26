import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("Glyph")
@MainActor
struct GlyphTests {
  /// drawn renders `view` at the screen's density, or nil where it draws nothing.
  private static func drawn(_ view: some View) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    return renderer.uiImage
  }

  @Test("a control's glyph is drawn from the control set in the colour it is handed, at its size")
  func control() throws {
    let image = try #require(Self.drawn(Glyph("zoom-in", size: 24, color: .red)))

    #expect(image.size == CGSize(width: 24, height: 24))
    // The plus: its bars cross at the centre, and the corners stay clear.
    let centre = try #require(Pixels.pixel(image, at: CGPoint(x: 12, y: 12)))
    #expect(centre.alpha == 255)
    #expect(centre.red > 200 && centre.green < 120 && centre.blue < 120, "\(centre)")
    #expect(Pixels.pixel(image, at: CGPoint(x: 2, y: 2))?.alpha == 0)
  }

  /// A glyph handed no colour reads `control-fg` as the controls do, as `sdk-kotlin`'s and
  /// `sdk-dart`'s glyphs do, whatever the text around it is drawn in.
  @Test("a glyph handed no colour is drawn in the control-fg token under the scheme in force")
  func tokenColour() throws {
    let glyph = Glyph("zoom-in", size: 24).foregroundStyle(.red)
    let light = try #require(Controls.drawn(glyph, scheme: .light))
    let dark = try #require(Controls.drawn(glyph, scheme: .dark))
    var tokens = ElementTokens.standard
    tokens.controlFg = ThemeToken(light: HexColor(hex: "#0b7285"))
    let restyled = try #require(Controls.drawn(glyph.mountayaTokens(tokens)))

    #expect(
      Pixels.pixel(light, at: CGPoint(x: 12, y: 12))?.isNear(Controls.color("#212529")) == true,
      "\(String(describing: Pixels.pixel(light, at: CGPoint(x: 12, y: 12))))")
    #expect(
      Pixels.pixel(dark, at: CGPoint(x: 12, y: 12))?.isNear(Controls.color("#c1c2c5")) == true,
      "\(String(describing: Pixels.pixel(dark, at: CGPoint(x: 12, y: 12))))")
    #expect(
      Pixels.pixel(restyled, at: CGPoint(x: 12, y: 12))?.isNear(Controls.color("#0b7285")) == true)
  }

  /// A control draws its face's glyph in the colour of its state, disabled or busy, which the glyph
  /// a view of the elements draws reads from the foreground style the control sets.
  @Test("a glyph of a control's face is drawn in the foreground style the face sets")
  func faceInk() throws {
    let face = Glyph("zoom-in", in: .control, size: 24, ink: .foreground).foregroundStyle(.red)
    let image = try #require(Controls.drawn(face))

    let centre = try #require(Pixels.pixel(image, at: CGPoint(x: 12, y: 12)))
    #expect(centre.red > 200 && centre.green < 120 && centre.blue < 120, "\(centre)")
  }

  @Test("a glyph of the set it is handed, scaled from the set's box to its size")
  func handedSet() throws {
    let block = try #require(
      GlyphSet(
        name: "block", paint: .fill, viewBox: 8,
        markup: ["half": #"<rect width="8" height="4"/>"#]))
    let image = try #require(Self.drawn(Glyph("half", in: block, size: 16).foregroundStyle(.black)))

    #expect(Pixels.pixel(image, at: CGPoint(x: 8, y: 4))?.alpha == 255)
    #expect(Pixels.pixel(image, at: CGPoint(x: 8, y: 12))?.alpha == 0)
  }

  @Test("a glyph handed no set is drawn from the control set of the scope around it")
  func scopeSet() throws {
    let block = try #require(
      GlyphSet(
        name: "block", paint: .fill, viewBox: 8,
        markup: ["zoom-in": #"<rect width="8" height="4"/>"#]))
    let scoped = try #require(
      Self.drawn(
        Glyph("zoom-in", size: 16).foregroundStyle(.black)
          .mountayaScope(ElementsScopeStatement(controlGlyphs: block))))
    let bundled = try #require(Self.drawn(Glyph("zoom-in", size: 16).foregroundStyle(.black)))

    // The scope's half block fills the top corner the bundled plus leaves clear.
    #expect(Pixels.pixel(scoped, at: CGPoint(x: 1, y: 1))?.alpha == 255)
    #expect(Pixels.pixel(scoped, at: CGPoint(x: 8, y: 12))?.alpha == 0)
    #expect(Pixels.pixel(bundled, at: CGPoint(x: 1, y: 1))?.alpha == 0)
    // A set handed over is drawn whatever the scope states.
    let handed = try #require(
      Self.drawn(
        Glyph("zoom-in", in: .control, size: 16).foregroundStyle(.black)
          .mountayaScope(ElementsScopeStatement(controlGlyphs: block))))
    #expect(Pixels.pixel(handed, at: CGPoint(x: 1, y: 1))?.alpha == 0)
  }

  @Test("a glyph the set does not hold is drawn as nothing and takes no room")
  func nothing() {
    #expect(Self.drawn(Glyph("hut")).map { $0.size.width * $0.size.height } ?? 0 == 0)
    #expect(Self.drawn(Glyph("hut", in: .marker, size: 24)) != nil)
  }
}
