/// GlyphSet is a set of glyphs drawn alike: the markup of each, by its name, and the paint, the
/// box and the stroke width every one of them is drawn at.
///
/// `GlyphSet.marker` and `GlyphSet.control` are the sets the contract's glyph table holds, the
/// marker set drawing every waypoint icon, amenity badge, restricted-stretch kind and point of
/// interest, and the control set every role a control draws, both stroked 2 units wide in a
/// 24-unit box (`geo.icons.bundled-sets`). A host draws a set of its own, a licensed one, by
/// building it from its markup, alone or chained over a bundled set. A glyph's markup is read into
/// shapes by `parseGlyph(_:)`, and each shape is painted as `glyphPaint(_:in:)` answers.
///
/// Every set can be drawn: each initializer refuses, by answering nil, what a renderer could not
/// draw, so a set fails where it is declared and never as a blank marker on a map.
///
/// Two are equal where they hold the same name, paint, width, box and markup, every text written
/// with the same scalars and every number the same number, 0 another than -0, as every value of
/// the geo layer compares; equal sets hash alike.
public struct GlyphSet: Sendable, Hashable {
  /// Paint is how a set's glyphs are drawn: each shape filled, or each shape stroked.
  public enum Paint: String, Sendable, Hashable, CaseIterable {
    /// fill fills each shape in the current colour and strokes none.
    case fill
    /// stroke strokes each shape in the current colour at the set's width and fills none.
    case stroke
  }

  /// name is the name the set is known by, never empty: a chain's is the names of its sets joined
  /// by `+`.
  public let name: String
  /// paint is how every glyph of the set is drawn.
  public let paint: Paint
  /// strokeWidth is the width a stroke set draws its glyphs at, and a fill set strokes a shape
  /// that asks for a stroke of its own at, in the units of its box.
  public let strokeWidth: Double
  /// viewBox is the side of the square box every glyph is drawn in.
  public let viewBox: Double
  /// markup is each glyph's markup, by the glyph's name: the set holds a glyph where it is a key.
  public let markup: [String: String]

  /// Creates a set from its name, the paint, the width and the box its glyphs are drawn at, and
  /// their markup, or nil where it cannot be drawn (`geo.icons.glyph-set`).
  ///
  /// A set that states no width is drawn at 2 and one that states no box in a box of 24, under
  /// either paint. It is refused where its name is empty, its box is no finite number above 0, or
  /// its width is no finite number, or is 0 or less for a stroke set, which a stroke of no width
  /// draws nothing for, or below 0 for a fill set, which reads its width only for a shape that
  /// asks for a stroke of its own.
  public init?(
    name: String, paint: Paint, strokeWidth: Double = 2, viewBox: Double = 24,
    markup: [String: String]
  ) {
    guard !name.isEmpty, viewBox.isFinite, viewBox > 0, strokeWidth.isFinite,
      paint == .stroke ? strokeWidth > 0 : strokeWidth >= 0
    else { return nil }
    self.init(
      drawable: name, paint: paint, strokeWidth: strokeWidth, viewBox: viewBox, markup: markup)
  }

  /// Creates the chain of `sets`, which answers each glyph from the first set that holds it and
  /// holds every glyph any set holds, all drawn in the first set's paint, box and width, or nil
  /// where the chain cannot be drawn alike (`geo.icons.glyph-set-chain`).
  ///
  /// It is refused where it chains no set, and where a later set differs from the first in paint
  /// or in box, or in width where the first strokes: a glyph drawn on another grid or for another
  /// weight would be drawn wrong, and a fill set's width is never compared. A partial licensed set
  /// chains over a bundled one of the same paint, box and width; across a paint, a host draws one
  /// set or the other.
  public init?(chaining sets: [GlyphSet]) {
    guard let first = sets.first else { return nil }
    for other in sets.dropFirst() {
      guard other.paint == first.paint, other.viewBox == first.viewBox,
        first.paint == .fill || other.strokeWidth == first.strokeWidth
      else { return nil }
    }
    var markup: [String: String] = [:]
    for set in sets {
      markup.merge(set.markup) { held, _ in held }
    }
    self.init(
      drawable: sets.map(\.name).joined(separator: "+"), paint: first.paint,
      strokeWidth: first.strokeWidth, viewBox: first.viewBox, markup: markup)
  }

  /// Creates a set from values already held to the bounds a set is drawn within: the bundled sets,
  /// which the printer holds to them, and a chain of sets that can each be drawn.
  init(
    drawable name: String, paint: Paint, strokeWidth: Double, viewBox: Double,
    markup: [String: String]
  ) {
    self.name = name
    self.paint = paint
    self.strokeWidth = strokeWidth
    self.viewBox = viewBox
    self.markup = markup
  }

  /// Two sets are equal where their name, paint, width, box and markup are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.name, rhs.name) && lhs.paint == rhs.paint
      && sameNumber(lhs.strokeWidth, rhs.strokeWidth) && sameNumber(lhs.viewBox, rhs.viewBox)
      && sameText(lhs.markup, rhs.markup)
  }

  /// hash feeds the name and the paint, the width and the box as the same-number relation reads
  /// them, then the markup in no order.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(paint)
    hasher.combine(sameNumber: strokeWidth)
    hasher.combine(sameNumber: viewBox)
    hasher.combine(markup)
  }
}
