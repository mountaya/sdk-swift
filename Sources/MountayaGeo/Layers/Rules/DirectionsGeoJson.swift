import MountayaClient

/// directionsGeoJson draws each route `result` answers, one line feature each in its order:
/// properties `distance`, `duration` and `summary`, `null` where the route states none,
/// `mtyaIndex` and `mtyaKind` `directions`.
public func directionsGeoJson(_ result: DataSchema.DirectionsResult) -> GeoJSONFeatureCollection {
  GeoJSONFeatureCollection(
    features: (result.routes ?? []).enumerated().map { index, route in
      GeoJSONFeature(
        geometry: route.geometry,
        properties: featureProperties(
          ("distance", numberProperty(route.distance)),
          ("duration", numberProperty(route.duration)),
          ("summary", textProperty(route.summary)),
          (featureIndexProperty, numberProperty(index)),
          (featureKindProperty, "directions")))
    })
}
