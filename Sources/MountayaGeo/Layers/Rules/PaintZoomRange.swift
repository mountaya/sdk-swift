import MountayaClient

/// paintZoomRange is the zoom window a tile specification paints across, its layers' and never its
/// sources': from the lowest `zoom_min` to the highest `zoom_max` of every layer of every one of
/// `sources`. A source's own zoom range says where its tiles are served, and a layer drawing from
/// it keeps painting past that on overzoomed tiles, so it bounds nothing here.
///
/// `nil` where no source holds a layer: nothing paints at any zoom.
public func paintZoomRange(_ sources: [TileSchema.TileSource]) -> ZoomBounds? {
  var lowest = Int.max
  var highest = Int.min
  var painted = false
  for source in sources {
    for layer in source.layers {
      painted = true
      lowest = min(lowest, layer.zoom_min)
      highest = max(highest, layer.zoom_max)
    }
  }
  guard painted else { return nil }
  return ZoomBounds(minZoom: Double(lowest), maxZoom: Double(highest))
}
