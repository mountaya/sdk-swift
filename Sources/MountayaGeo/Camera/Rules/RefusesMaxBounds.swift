/// refusesMaxBounds tells whether a pan lock with edges `[west, south, east, north]` in degrees,
/// as it is about to be handed to a renderer, is refused before it reaches it: whether it encloses
/// no area.
///
/// A renderer divides the canvas by a lock's width and height, and fails on one that measures
/// nothing in words that name nothing the caller wrote. A lock is refused where its west and east
/// edges are a whole number of turns apart, none included, so that they fall on one meridian;
/// where its south and north edges are one parallel; and where an edge is at no finite
/// coordinate, `NaN` or an infinity. A lock that is not four numbers encloses no area either. An
/// east edge west of the west edge is a lock across the antimeridian, and is not refused for it,
/// and neither is a lock drawn upside down, which still has a height.
///
/// It is a predicate rather than a throw, since no rule of the geo layer throws and the class of
/// the refusal is the map engine's: `MapEngine.setMaxBounds(_:)` refuses such a lock with a
/// `MapError`, the map left as it was, and a consumer drawing a map of their own asks it of a lock
/// before their renderer does.
public func refusesMaxBounds(_ edges: [Double]) -> Bool {
  guard edges.count == 4, edges.allSatisfy(\.isFinite) else { return true }
  let (west, south, east, north) = (edges[0], edges[1], edges[2], edges[3])
  return (east - west).truncatingRemainder(dividingBy: degreesPerTurn) == 0 || south == north
}
