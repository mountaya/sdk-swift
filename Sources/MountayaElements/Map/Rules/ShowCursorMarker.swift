/// cursorMarkerGlyph is the glyph an element's cursor marker is drawn with where its caller names
/// none, the `glyph` `map/profile-cursor-marker.json` declares: the filled pin, which stands in the
/// control set alone, so on a map drawing the bundled marker set the marker is the pin's dot
/// (`map.marker.pin`).
public let cursorMarkerGlyph = "pin-filled"

/// profileCursorMarkerId is the id a profile pins its cursor marker under where its caller names
/// none, one of the `markerIds` `map/profile-cursor-marker.json` declares, so a profile and two
/// tables over one map never move or take down each other's marker.
public let profileCursorMarkerId = "mtya-profile-cursor"

/// segmentTableCursorMarkerId is the id a segment table pins its cursor marker under where its
/// caller names none.
public let segmentTableCursorMarkerId = "mtya-segment-table-cursor"

/// waypointTableCursorMarkerId is the id a waypoint table pins its cursor marker under where its
/// caller names none.
public let waypointTableCursorMarkerId = "mtya-waypoint-table-cursor"

/// showCursorMarker pins an element's cursor marker on `map` where the cursor stands, `point`, and
/// answers what the marker is drawn with (`map.profile.cursor-marker`).
///
/// A marker the element added, `pinned`, drawn with the point's colour and glyph, is moved by
/// editing its position, so a label opened on it stays open; one whose colour or glyph changed is
/// added again, since an edit cannot take a colour off, and so is one something else took down, the
/// edit finding no marker. It throws what the map throws for a write it refuses, but a missing
/// marker on an edit.
@MainActor
public func showCursorMarker(
  on map: some CursorMarkerTarget, pinned: CursorMarkerPin?, point: CursorMarkerPoint
) throws(MapError) -> CursorMarkerPin {
  let position = Array(point.lngLat.prefix(2))
  let drawn = CursorMarkerPin(color: point.color, glyph: point.glyph)
  if pinned == drawn {
    do {
      try map.editMarker(point.id, position: position, color: nil, glyph: nil, label: nil)
      return drawn
    } catch  where error.kind == .markerNotFound {
      // The marker is gone, and is added again below.
    }
  }
  try map.addMarker(
    MapMarker(id: point.id, position: position, color: point.color, glyph: point.glyph))
  return drawn
}
