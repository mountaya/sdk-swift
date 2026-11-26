import MountayaGeo

/// stripeTilePx is the side of a stripe pattern's square tile, in pixels: one stripe and its gap
/// at the zooms a route is drawn at, a power of two a renderer repeats cleanly.
let stripeTilePx: Double = 16

/// roadAccessStripeWidthPx is the width of each stripe of a restricted stretch's pattern, in
/// pixels: the stripes and the ground between them close to equal, so the stretch reads as hazard
/// tape at a route's narrow width.
let roadAccessStripeWidthPx: Double = 6

/// roadAccessStripeGround is what shows between the stripes of a restricted stretch: white, so the
/// stripes of a kind read over a route drawn in any colour, that kind's own included.
let roadAccessStripeGround = "#ffffff"

/// roadAccessStripePattern answers how a restricted stretch of `kind` is striped: a 16-pixel tile
/// of stripes 6 pixels wide rising at 45 degrees with round ends, in the kind's colour
/// (`roadAccessColor(_:)`) on white (`map.icons.stripe-pattern`).
///
/// The stripe through the tile runs from its lower left corner to its upper right one, and the two
/// halves that complete its neighbours run past the tile's edges, so the tile repeats with no seam.
func roadAccessStripePattern(_ kind: RoadAccessKind) -> StripePattern {
  let size = stripeTilePx
  let half = size / 2
  return StripePattern(
    size: size, width: roadAccessStripeWidthPx, color: roadAccessColor(kind).hex,
    ground: roadAccessStripeGround, lineCap: .round,
    segments: [
      [[-half, half], [half, -half]],
      [[0, size], [size, 0]],
      [[half, size + half], [size + half, half]],
    ])
}
