import MountayaGeo

/// zoomWindowAfter is the zoom window a map holds once a call states `min` and `max` over the
/// window `held` (`map.camera.zoom-window`), on a renderer whose own limits are `renderer`: its
/// floor, under which no window reaches, and the ceiling it builds a map with.
///
/// A limit kept stays where `held` has it; a limit released goes back to the renderer's own, the
/// floor to its floor and the ceiling to its ceiling, and is read as that zoom from there on; a
/// limit moved takes its zoom. A window whose floor lies at or under its ceiling is taken whatever
/// window is held, one above it included. A window that is the one held answers it, which is no
/// move, and so nothing to tell.
///
/// It throws, with nothing applied, a `MapError` of kind `numberRefused` where a limit stated is
/// not a finite number, and of kind `zoomBoundsRefused` where the floor stated lies under the
/// renderer's floor, where the floor lies above the ceiling stated beside it, where a floor stated
/// alone lies above the ceiling held, or where a ceiling stated alone lies under the floor held,
/// in the order the contract's first SDK reads them: the floor, then the ceiling, then the two
/// together.
func zoomWindowAfter(_ held: ZoomBounds, min: ZoomLimit, max: ZoomLimit, renderer: ZoomBounds)
  throws(MapError) -> ZoomBounds
{
  let floor = stated(min, released: renderer.minZoom)
  let ceiling = stated(max, released: renderer.maxZoom)
  let written = "\(floor.map { "\($0)" } ?? "kept")...\(ceiling.map { "\($0)" } ?? "kept")"
  if let floor {
    guard floor.isFinite else { throw MapError(kind: .numberRefused, name: written) }
    guard floor >= renderer.minZoom else {
      throw MapError(kind: .zoomBoundsRefused, name: written)
    }
  }
  if let ceiling, !ceiling.isFinite {
    throw MapError(kind: .numberRefused, name: written)
  }
  switch (floor, ceiling) {
  case (let floor?, let ceiling?) where floor > ceiling:
    throw MapError(kind: .zoomBoundsRefused, name: written)
  case (let floor?, nil) where floor > held.maxZoom:
    throw MapError(kind: .zoomBoundsRefused, name: written)
  case (nil, let ceiling?) where ceiling < held.minZoom:
    throw MapError(kind: .zoomBoundsRefused, name: written)
  default:
    return ZoomBounds(minZoom: floor ?? held.minZoom, maxZoom: ceiling ?? held.maxZoom)
  }
}

/// stated is the zoom a limit states, the renderer's own where it is released, or nil where it is
/// kept.
private func stated(_ limit: ZoomLimit, released: Double) -> Double? {
  switch limit {
  case .kept: nil
  case .released: released
  case .zoom(let zoom): zoom
  }
}
