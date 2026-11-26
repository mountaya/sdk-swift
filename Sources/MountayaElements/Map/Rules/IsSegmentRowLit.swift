import MountayaGeo

/// isSegmentRowLit tells whether a segment table's `row` is lit (`map.profile.table-rows`): where
/// the reader points at it, `pointed` being its key, and where it stands for the leg the app names,
/// `highlighted`, or, where the app names none, the leg the map's own cursor is over, `hovered`, a
/// collapsed group's row standing for each of its members (`rowStandsFor(_:id:)`). A row the app
/// names is lit in place of the one the map's cursor would light, whatever leg the cursor is over.
func isSegmentRowLit(
  _ row: ItinerarySegmentRow, pointed: String?, highlighted: String?, hovered: String?
) -> Bool {
  pointed.map { sameText(row.key, $0) } == true || rowStandsFor(row, id: highlighted ?? hovered)
}
