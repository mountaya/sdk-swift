/// GlyphDrawing is one of Mountaya's own drawings, which no glyph set holds since each of its
/// shapes is painted on its own: the compass rose, whose needle keeps its colour while its disc
/// follows the scheme, the profile's marker, and the watermark a map draws, whose shapes are
/// filled with gradients under an opacity and a drop shadow of the drawing's own.
///
/// `GlyphDrawing.artwork` holds the drawings the contract's glyph table carries, by name.
///
/// Two drawings, two shapes and two paints are equal where they hold the same, every text written
/// with the same scalars and every number the same number, `NaN` the same as `NaN` and 0 another
/// than -0, as every value of the geo layer compares; equal values hash alike.
public struct GlyphDrawing: Sendable, Hashable {
  /// Paint is a shape's fill or stroke: a colour of its own, or one of the elements' colour
  /// tokens, each at an opacity.
  public enum Paint: Sendable, Hashable {
    /// color is a colour the drawing fixes, whatever the scheme.
    case color(HexColor)
    /// token is one of `ElementTokens`' colours, read under the scheme drawn in, at an opacity.
    case token(any KeyPath<ElementTokens, ThemeToken<HexColor>> & Sendable, opacity: Double)
    /// linear is a linear gradient the drawing fixes, whatever the scheme.
    case linear(Gradient)

    /// Two paints are equal where they are the same colour, the same token at the same opacity,
    /// or the same gradient.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.color(let a), .color(let b)): a == b
      case (.token(let a, let c), .token(let b, let d)): a == b && sameNumber(c, d)
      case (.linear(let a), .linear(let b)): a == b
      default: false
      }
    }

    /// hash feeds the kind, then the colour, or the token and its opacity as the same-number
    /// relation reads it.
    public func hash(into hasher: inout Hasher) {
      switch self {
      case .color(let color):
        hasher.combine(0)
        hasher.combine(color)
      case .token(let token, let opacity):
        hasher.combine(1)
        hasher.combine(token)
        hasher.combine(sameNumber: opacity)
      case .linear(let gradient):
        hasher.combine(2)
        hasher.combine(gradient)
      }
    }
  }

  /// Gradient is a linear gradient over the drawing's own units, as SVG's `userSpaceOnUse` draws
  /// one: its colours run from `from` to `to`, `[x, y]` each, and hold their end stops' colours
  /// past either end.
  public struct Gradient: Sendable, Hashable {
    /// from is where the gradient starts, `[x, y]` in the units of the drawing's box.
    public var from: [Double]
    /// to is where the gradient ends, `[x, y]` in the units of the drawing's box.
    public var to: [Double]
    /// stops are the gradient's colours, at offsets rising from 0 to 1 along it.
    public var stops: [GradientStop]

    /// Creates a gradient from its two ends and its stops.
    public init(from: [Double], to: [Double], stops: [GradientStop]) {
      self.from = from
      self.to = to
      self.stops = stops
    }

    /// Two gradients are equal where their ends hold the same numbers and their stops are the
    /// same, in the same order.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumbers(lhs.from, rhs.from) && sameNumbers(lhs.to, rhs.to) && lhs.stops == rhs.stops
    }

    /// hash feeds the ends as the same-number relation reads them, then the stops in order.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(sameNumbers: from)
      hasher.combine(sameNumbers: to)
      hasher.combine(stops)
    }
  }

  /// GradientStop is one colour of a gradient, at its offset along it, from 0 to 1.
  public struct GradientStop: Sendable, Hashable {
    /// offset is where along the gradient the colour stands, from 0 at `from` to 1 at `to`.
    public var offset: Double
    /// color is the colour at the stop, with its opacity.
    public var color: HexColor

    /// Creates a stop of `color` at `offset`.
    public init(offset: Double, color: HexColor) {
      self.offset = offset
      self.color = color
    }

    /// Two stops are equal where their offsets are the same number and their colours the same.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumber(lhs.offset, rhs.offset) && lhs.color == rhs.color
    }

    /// hash feeds the offset as the same-number relation reads it, then the colour.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(sameNumber: offset)
      hasher.combine(color)
    }
  }

  /// Shadow is a drop shadow a drawing casts behind its shapes, as SVG's filter of one: the
  /// shapes' silhouette, offset by `dx` and `dy`, blurred by a Gaussian of standard deviation
  /// `blur`, each in the units of the drawing's box, and painted in `color`.
  public struct Shadow: Sendable, Hashable {
    /// blur is the standard deviation of the Gaussian the silhouette is blurred by.
    public var blur: Double
    /// dx is how far right of the shapes the shadow falls.
    public var dx: Double
    /// dy is how far below the shapes the shadow falls.
    public var dy: Double
    /// color is the shadow's colour, with its opacity.
    public var color: HexColor

    /// Creates a shadow from its blur, its offset and its colour.
    public init(blur: Double, dx: Double, dy: Double, color: HexColor) {
      self.blur = blur
      self.dx = dx
      self.dy = dy
      self.color = color
    }

    /// Two shadows are equal where their numbers are the same and their colours the same.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumber(lhs.blur, rhs.blur) && sameNumber(lhs.dx, rhs.dx) && sameNumber(lhs.dy, rhs.dy)
        && lhs.color == rhs.color
    }

    /// hash feeds the numbers as the same-number relation reads them, then the colour.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(sameNumber: blur)
      hasher.combine(sameNumber: dx)
      hasher.combine(sameNumber: dy)
      hasher.combine(color)
    }
  }

  /// PaintedShape is one shape of a drawing: its markup and the paint it is drawn in.
  public struct PaintedShape: Sendable, Hashable {
    /// markup is the shape's markup, read into shapes by `parseGlyph(_:)`.
    public var markup: String
    /// fill is what the shape is filled with, or nil where it is not filled.
    public var fill: Paint?
    /// stroke is what the shape is stroked with, or nil where it is not stroked.
    public var stroke: Paint?
    /// strokeWidth is the width of the shape's stroke, in the units of the drawing's box, or nil
    /// where it is not stroked.
    public var strokeWidth: Double?

    /// Creates a shape from its markup and its paint.
    public init(
      markup: String, fill: Paint? = nil, stroke: Paint? = nil, strokeWidth: Double? = nil
    ) {
      self.markup = markup
      self.fill = fill
      self.stroke = stroke
      self.strokeWidth = strokeWidth
    }

    /// Two shapes are equal where their markup, their paints and their width are the same, an
    /// absent paint or width the same only as another absent one.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.markup, rhs.markup) && lhs.fill == rhs.fill && lhs.stroke == rhs.stroke
        && sameNumber(lhs.strokeWidth, rhs.strokeWidth)
    }

    /// hash feeds the markup and the paints, then the width as the same-number relation reads it.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(markup)
      hasher.combine(fill)
      hasher.combine(stroke)
      hasher.combine(sameNumber: strokeWidth)
    }
  }

  /// viewBox is the box the shapes are drawn in, `[x, y, width, height]`.
  public var viewBox: [Double]
  /// opacity is how opaque the drawing is as a whole, its shapes and its shadow composed first,
  /// from 0 to 1.
  public var opacity: Double
  /// shadow is the drop shadow the drawing casts behind its shapes, or nil for none.
  public var shadow: Shadow?
  /// shapes are the drawing's shapes, in drawing order.
  public var shapes: [PaintedShape]

  /// Creates a drawing from its box and its shapes, opaque and casting no shadow.
  public init(viewBox: [Double], shapes: [PaintedShape]) {
    self.init(viewBox: viewBox, opacity: 1, shadow: nil, shapes: shapes)
  }

  /// Creates a drawing from its box, its opacity, its shadow and its shapes.
  public init(viewBox: [Double], opacity: Double, shadow: Shadow?, shapes: [PaintedShape]) {
    self.viewBox = viewBox
    self.opacity = opacity
    self.shadow = shadow
    self.shapes = shapes
  }

  /// Two drawings are equal where their boxes hold the same numbers, their opacities and their
  /// shadows are the same, and their shapes are the same, in the same order.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumbers(lhs.viewBox, rhs.viewBox) && sameNumber(lhs.opacity, rhs.opacity)
      && lhs.shadow == rhs.shadow && lhs.shapes == rhs.shapes
  }

  /// hash feeds the box and the opacity as the same-number relation reads them, then the shadow and
  /// the shapes in order.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumbers: viewBox)
    hasher.combine(sameNumber: opacity)
    hasher.combine(shadow)
    hasher.combine(shapes)
  }
}
