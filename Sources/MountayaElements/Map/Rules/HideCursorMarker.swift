/// hideCursorMarker takes an element's cursor marker, pinned under `id`, down from `map` where the
/// cursor no longer stands or the element goes (`map.profile.cursor-marker`), only where the element
/// added it, `pinned`: a marker another holder of the id pinned is never its to take. The element
/// holds no marker after it.
@MainActor
public func hideCursorMarker(on map: some CursorMarkerTarget, pinned: CursorMarkerPin?, id: String)
{
  guard pinned != nil else { return }
  map.removeMarker(id)
}
