import MountayaGeo

/// StripePattern is how a stripe pattern is drawn, the square tile a stretch of a route is painted
/// with, repeated along it (`map.icons.stripe-pattern`): the ground it is filled with, and stripes
/// stroked over it with round ends.
///
/// Every length is in the tile's pixels. Two are equal where every member is the same, a number by
/// the same-number relation and a colour by its scalars.
struct StripePattern: Sendable, Equatable {
  /// size is the side of the square tile.
  let size: Double
  /// width is the stroke width of each stripe.
  let width: Double
  /// color is the colour the stripes are stroked in.
  let color: String
  /// ground is the colour the tile is filled with under the stripes, or nil for gaps that show
  /// what is drawn beneath.
  let ground: String?
  /// lineCap is how each end of a stripe is drawn.
  let lineCap: ShapePaint.LineCap
  /// segments are the stripes, each from its lower left end to its upper right one, `[x, y]` from
  /// the tile's top left corner: the stripe through the tile and the two halves that complete it
  /// across the tile's edges, so the tile repeats with no seam.
  let segments: [[[Double]]]

  static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.size, rhs.size) && sameNumber(lhs.width, rhs.width)
      && sameText(lhs.color, rhs.color) && sameText(lhs.ground, rhs.ground)
      && lhs.lineCap == rhs.lineCap && lhs.segments.count == rhs.segments.count
      && zip(lhs.segments, rhs.segments).allSatisfy { a, b in
        a.count == b.count && zip(a, b).allSatisfy { sameNumbers($0, $1) }
      }
  }
}
