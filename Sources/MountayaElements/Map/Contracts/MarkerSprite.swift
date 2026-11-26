import MountayaGeo

/// MarkerSprite is what a marker sprite draws, the image a waypoint's or a point of interest's
/// symbol layer names for a glyph in a colour (`map.icons.marker-sprite`): a square colour image
/// the style never recolours, a disc at its centre under a border, and the glyph fitted to the
/// square half the image wide at its centre.
///
/// Every length is in the image's pixels, which a renderer draws at its screen's density, so a
/// sprite is the same size on every screen. Two are equal where every member is the same, a number
/// by the same-number relation and a colour by its scalars.
struct MarkerSprite: Sendable, Equatable {
  /// Disc is the disc the glyph stands on.
  struct Disc: Sendable, Equatable {
    /// center is the disc's centre, `[x, y]` from the image's top left corner.
    let center: [Double]
    /// radius is the disc's radius, to the middle of its border.
    let radius: Double
    /// fill is the feature's colour, as given, which the disc is filled with.
    let fill: String
    /// borderColor is the colour of the border drawn around the disc, centred on its edge.
    let borderColor: String
    /// borderWidth is the border's width.
    let borderWidth: Double

    static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumbers(lhs.center, rhs.center) && sameNumber(lhs.radius, rhs.radius)
        && sameText(lhs.fill, rhs.fill) && sameText(lhs.borderColor, rhs.borderColor)
        && sameNumber(lhs.borderWidth, rhs.borderWidth)
    }
  }

  /// GlyphFit is where the glyph is drawn, and in what colour: the set's view box starts `offset`
  /// pixels from the image's left and top edges, and one of its units is `scale` pixels, so a set
  /// drawn on any grid fills the same square.
  struct GlyphFit: Sendable, Equatable {
    /// offset is how far the glyph's square starts from the image's left and top edges.
    let offset: Double
    /// scale is how many pixels one unit of the set's view box is drawn as.
    let scale: Double
    /// color is the colour the glyph's current colour is.
    let color: String

    static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumber(lhs.offset, rhs.offset) && sameNumber(lhs.scale, rhs.scale)
        && sameText(lhs.color, rhs.color)
    }
  }

  /// size is the side of the square image.
  let size: Double
  /// disc is the disc the glyph stands on.
  let disc: Disc
  /// glyph is where the glyph is drawn, painted as its set paints it.
  let glyph: GlyphFit

  static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.size, rhs.size) && lhs.disc == rhs.disc && lhs.glyph == rhs.glyph
  }
}
