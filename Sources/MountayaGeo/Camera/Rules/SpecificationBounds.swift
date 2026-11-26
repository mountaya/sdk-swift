/// specificationBounds is the box a collection is framed on (`geo.camera.content-bounds`): the
/// `bbox` its tile specification states, read in the form every other box of the geo layer takes.
///
/// The Tile API writes a box across the antimeridian as RFC 7946 writes one, its west edge east of
/// its east one, `[179.8, -17, -179.9, -16]`; such a box is read as `[west, south, east + 360,
/// north]`, `[179.8, -17, 180.1, -16]`, 0.3 degrees wide, as `boundsOf(_:)` frames one, where
/// `normalizeBoundingBox(_:)` handed it as received would read a box 359.7 degrees wide. Any other
/// box is answered as written.
///
/// The answer is nil where the specification states no box, which frames nothing, and where the
/// box it states is not four numbers.
public func specificationBounds(_ bbox: [Double]?) -> [Double]? {
  guard let bbox, bbox.count == 4 else { return nil }
  guard bbox[0] > bbox[2] else { return bbox }
  return [bbox[0], bbox[1], bbox[2] + degreesPerTurn, bbox[3]]
}
