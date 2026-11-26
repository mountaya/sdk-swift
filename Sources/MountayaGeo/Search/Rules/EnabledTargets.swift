import MountayaClient

/// enabledTargets is the targets of a search request that asks the branch `branch` alone
/// (`geo.search.section-order`): its flag true and every other flag false, each stated, so the
/// request says what it asks whatever the API's defaults.
///
/// `nil` for a branch this build cannot enable, one the contract added after it, which no request
/// of it can ask. Every branch is named, so a target the contract adds is one more case here rather
/// than a section that renders and is always empty.
func enabledTargets(_ branch: DataSchema.SearchTarget) -> DataSchema.SearchTargetsInput? {
  let known: [DataSchema.SearchTarget] = [
    .places, .pois, .ways, .itineraries, .collections, .zones,
  ]
  guard known.contains(where: { sameText($0, branch) }) else { return nil }
  return DataSchema.SearchTargetsInput {
    $0.places = sameText(branch, .places)
    $0.pois = sameText(branch, .pois)
    $0.ways = sameText(branch, .ways)
    $0.itineraries = sameText(branch, .itineraries)
    $0.collections = sameText(branch, .collections)
    $0.zones = sameText(branch, .zones)
  }
}
