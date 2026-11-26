import MountayaClient

/// MapTarget is what a data element writes to the map while a reader points at it: the position
/// its cursor marker stands at, and the stretch lit on the emphasis slot, each nil for none.
struct MapTarget: Equatable {
  var lngLat: [Double]?
  var stretch: GeoJSONGeometry?
}
