import MountayaClient

/// writeLegEmphasis lights the stretch an element points at on `map`'s emphasis slot, in `color`,
/// the map's own where it is nil, or takes down what the element lit where it points at none,
/// `stretch` nil, and answers whether the slot holds the element's stretch afterwards
/// (`map.profile.emphasis`). The stretch is the series cut between the leg's two ends
/// (`lineBetween(_:from:to:)`), the line the chart drew.
///
/// An element clears only a slot it wrote, `isLit`: two elements over one map would otherwise take
/// turns clearing each other's stretch as a pointer left one for the other, and an element that
/// never pointed at a leg leaves the slot as it found it.
@MainActor
public func writeLegEmphasis(
  on map: some LegEmphasisTarget, isLit: Bool, stretch: GeoJSONGeometry?, color: String? = nil
) -> Bool {
  guard let stretch else {
    if isLit { map.clearGeometry(in: .emphasis) }
    return false
  }
  map.setGeometry(stretch, in: .emphasis, color: color)
  return true
}
