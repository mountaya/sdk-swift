/// canonicalLongitudes writes the west and east edges of a box, the west at or west of the east,
/// in the form every box of the geo layer takes, as `[west, east]`: the west edge brought within
/// [-180, 180] by whole turns and the east edge moved by the same turns, past 180 where the box
/// crosses the antimeridian. A west edge already within [-180, 180] keeps its digits, 180
/// included.
///
/// A box a turn or more wide covers every longitude and is the whole world, `[-180, 180]`, and so
/// is one with its west edge at the western infinity or its east edge at the eastern one. An edge
/// that is `NaN`, both edges at one infinity, and edges handed east first with one at an infinity
/// place the box at no longitude, and both edges answer `NaN`: no whole turn brings an infinite
/// edge back.
func canonicalLongitudes(west: Double, east: Double) -> [Double] {
  let span = east - west
  if span >= degreesPerTurn { return [-longitudeLimit, longitudeLimit] }
  if span.isNaN || span == -.infinity { return [.nan, .nan] }
  // Both edges are finite here. The whole turns that bring the west edge within [-180, 180], and
  // none for a west edge already there, so one on 180 itself stays where it is written.
  let outsideOneWorld = west < -longitudeLimit || west > longitudeLimit
  let turns = outsideOneWorld ? ((west + longitudeLimit) / degreesPerTurn).rounded(.down) : 0
  return [west - turns * degreesPerTurn, east - turns * degreesPerTurn]
}
