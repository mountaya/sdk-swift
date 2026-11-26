// swift-format-ignore-file
// Printed by `swift run GenerateClient` from `sdk/elements/glyphs.json`, model digest
// c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong value is a defect in `mountaya/schemas`, fixed there and printed
// again (SPEC.md section 3).

extension GlyphDrawing {
  /// artwork is Mountaya's own drawings the contract's glyph table carries, by the name it gives
  /// each.
  public static let artwork: [String: GlyphDrawing] = [
    "compass-rose": GlyphDrawing(
      viewBox: [0, 0, 32, 32],
      shapes: [
        PaintedShape(markup: "<rect height=\"32\" rx=\"16\" width=\"32\" />", fill: .token(\ElementTokens.controlBg, opacity: 1)),
        PaintedShape(markup: "<path d=\"M16 7 12 16h8z\" />", fill: .color(HexColor(hex: "#e9501e"))),
        PaintedShape(markup: "<path d=\"M16 25 12 16h8z\" />", fill: .token(\ElementTokens.accent, opacity: 0.45), stroke: .color(HexColor(hex: "#000000", opacity: 0.25)), strokeWidth: 1),
      ]
    ),
    "watermark": GlyphDrawing(
      viewBox: [0, 0, 138, 58],
      opacity: 0.9,
      shadow: Shadow(blur: 12.1452, dx: 0, dy: 0, color: HexColor(hex: "#000000", opacity: 0.55)),
      shapes: [
        PaintedShape(markup: "<path d=\"M22 16h7v7h-7z\" />", fill: .linear(Gradient(from: [23.7246, 40.8919], to: [22.8662, 18.575], stops: [GradientStop(offset: 0, color: HexColor(hex: "#090b0e")), GradientStop(offset: 1, color: HexColor(hex: "#dddbdc", opacity: 0.6))]))),
        PaintedShape(markup: "<path d=\"M49 30h-2l-1-7z\" />", fill: .color(HexColor(hex: "#ffffff"))),
      ]
    ),
  ]
}
