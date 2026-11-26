import Testing

@testable import MountayaGeo

@Suite("GlyphDrawing")
struct GlyphDrawingTests {
  @Test("the compass rose follows the scheme in its disc and letter, and fixes its needle's colour")
  func compassRose() throws {
    let rose = try #require(GlyphDrawing.artwork["compass-rose"])

    #expect(rose.viewBox == [0, 0, 32, 32])
    #expect(rose.shapes.count == 4)
    #expect(rose.shapes.first?.fill == .token(\ElementTokens.controlBg, opacity: 1))
    #expect(rose.shapes[1].fill == .color(HexColor(hex: "#e9501e")))
    #expect(rose.shapes.last?.fill == .token(\ElementTokens.controlFg, opacity: 0.45))
    #expect(rose.shapes.allSatisfy { $0.stroke == nil && $0.strokeWidth == nil })
  }

  @Test("the profile's marker is filled white and stroked in a translucent black one unit wide")
  func profileMarker() throws {
    let marker = try #require(GlyphDrawing.artwork["profile-marker"])

    #expect(marker.viewBox == [0, 0, 24, 33])
    #expect(marker.shapes.first?.fill == .color(HexColor(hex: "#ffffff")))
    #expect(marker.shapes.first?.stroke == .color(HexColor(hex: "#000000", opacity: 0.25)))
    #expect(marker.shapes.first?.strokeWidth == 1)
  }

  @Test("the watermark is drawn under its opacity and its shadow, its mark filled with gradients")
  func watermark() throws {
    let mark = try #require(GlyphDrawing.artwork["watermark"])

    #expect(mark.viewBox == [0, 0, 138, 58])
    #expect(mark.opacity == 0.9)
    #expect(mark.shadow?.blur == 12.1452)
    #expect(mark.shadow?.color == HexColor(hex: "#000000", opacity: 0.55))
    guard case .linear(let gradient)? = mark.shapes.first?.fill else {
      Issue.record("the mark's first shape is filled with no gradient")
      return
    }
    #expect(gradient.stops.count == 2)
  }

  @Test("every printed shape is markup the glyph reader reads into shapes")
  func readable() {
    #expect(GlyphDrawing.artwork.count == 3)
    for (name, drawing) in GlyphDrawing.artwork {
      for shape in drawing.shapes {
        #expect(!parseGlyph(shape.markup).isEmpty, "\(name)")
      }
    }
  }

  @Test("two paints are one where they name the same colour, or the same token at one opacity")
  func paints() {
    #expect(
      GlyphDrawing.Paint.token(\ElementTokens.accent, opacity: 1)
        == .token(\ElementTokens.accent, opacity: 1))
    #expect(
      GlyphDrawing.Paint.token(\ElementTokens.accent, opacity: 1)
        != .token(\ElementTokens.accent, opacity: 0.5))
    #expect(
      GlyphDrawing.Paint.token(\ElementTokens.accent, opacity: 1)
        != .token(\ElementTokens.controlBg, opacity: 1))
    #expect(
      GlyphDrawing.Paint.color(HexColor(hex: "#ffffff"))
        != .token(\ElementTokens.panelBg, opacity: 1))
  }

  @Test("two paints compare their opacity as the same number, and equal paints hash alike")
  func samePaints() {
    let unknown = GlyphDrawing.Paint.token(\ElementTokens.accent, opacity: .nan)
    let signed = GlyphDrawing.Paint.token(\ElementTokens.accent, opacity: -.nan)
    let veiled = GlyphDrawing.Paint.color(HexColor(hex: "#000000", opacity: .nan))

    #expect(unknown == signed)
    #expect(unknown.hashValue == signed.hashValue)
    #expect(
      GlyphDrawing.Paint.token(\ElementTokens.accent, opacity: 0)
        != .token(\ElementTokens.accent, opacity: -0.0))
    #expect(veiled == .color(HexColor(hex: "#000000", opacity: -.nan)))
    #expect(
      veiled.hashValue
        == GlyphDrawing.Paint.color(HexColor(hex: "#000000", opacity: -.nan)).hashValue)
    #expect(
      GlyphDrawing.Paint.color(HexColor(hex: "#000000", opacity: 0))
        != .color(HexColor(hex: "#000000", opacity: -0.0)))
  }

  @Test("two drawings compare their markup by scalars and every number as the same number")
  func sameDrawings() {
    func drawing(
      viewBox: [Double] = [0, 0, 24, 24], markup: String = "<circle r=\"1\" />",
      strokeWidth: Double? = 1
    ) -> GlyphDrawing {
      GlyphDrawing(
        viewBox: viewBox,
        shapes: [
          GlyphDrawing.PaintedShape(
            markup: markup, stroke: .color(HexColor(hex: "#000000")), strokeWidth: strokeWidth)
        ])
    }
    let unknown = drawing(strokeWidth: .nan)

    #expect(unknown == drawing(strokeWidth: -.nan))
    #expect(unknown.hashValue == drawing(strokeWidth: -.nan).hashValue)
    #expect(Set([unknown, drawing(strokeWidth: .nan)]).count == 1)
    #expect(
      unknown.shapes[0]
        == GlyphDrawing.PaintedShape(
          markup: "<circle r=\"1\" />", stroke: .color(HexColor(hex: "#000000")), strokeWidth: .nan)
    )
    #expect(drawing(viewBox: [0, 0, .nan, 24]) == drawing(viewBox: [0, 0, -.nan, 24]))
    #expect(drawing(strokeWidth: 0) != drawing(strokeWidth: -0.0))
    #expect(Set([drawing(strokeWidth: 0), drawing(strokeWidth: -0.0)]).count == 2)
    #expect(drawing(viewBox: [0, 0, 24, 24]) != drawing(viewBox: [-0.0, 0, 24, 24]))
    #expect(drawing(strokeWidth: nil) != drawing(strokeWidth: 0))
    #expect(drawing(markup: "<text>\u{E9}</text>") != drawing(markup: "<text>e\u{301}</text>"))
  }

  @Test(
    "a drawing compares its opacity, its shadow and its gradients, each number as the same number")
  func opacityShadowGradient() {
    let gradient = GlyphDrawing.Gradient(
      from: [0, 1], to: [2, 3],
      stops: [
        GlyphDrawing.GradientStop(offset: 0, color: HexColor(hex: "#090b0e")),
        GlyphDrawing.GradientStop(offset: 1, color: HexColor(hex: "#ffffff", opacity: 0.6)),
      ])
    let shadow = GlyphDrawing.Shadow(
      blur: 12.1452, dx: 0, dy: 0, color: HexColor(hex: "#000000", opacity: 0.55))
    let shape = GlyphDrawing.PaintedShape(markup: "<path d=\"M0 0h1\" />", fill: .linear(gradient))
    let drawing = GlyphDrawing(
      viewBox: [0, 0, 138, 58], opacity: 0.9, shadow: shadow, shapes: [shape])

    #expect(
      drawing
        == GlyphDrawing(viewBox: [0, 0, 138, 58], opacity: 0.9, shadow: shadow, shapes: [shape]))
    #expect(drawing.hashValue == drawing.hashValue)
    #expect(drawing != GlyphDrawing(viewBox: [0, 0, 138, 58], shapes: [shape]))
    #expect(GlyphDrawing(viewBox: [0, 0, 1, 1], shapes: []).opacity == 1)
    #expect(GlyphDrawing(viewBox: [0, 0, 1, 1], shapes: []).shadow == nil)
    var moved = shadow
    moved.dx = -0.0
    #expect(moved != shadow)
    #expect(GlyphDrawing.Paint.linear(gradient) != .color(HexColor(hex: "#090b0e")))
  }
}
