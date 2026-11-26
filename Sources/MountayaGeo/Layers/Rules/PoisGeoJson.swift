import MountayaClient

/// poiResultPointColor is the fill of a point of interest's marker.
public let poiResultPointColor = "#1c7ed6"

/// poisGeoJson draws `result`'s points of interest, one point feature each in its order, no
/// geometry for one whose point names no place: properties `category`, `distanceMeters`,
/// `elevation` and `name`, `null` where the point states none, `mtyaColor` `poiResultPointColor`,
/// `mtyaIndex` and `mtyaKind` `poi`.
public func poisGeoJson(_ result: DataSchema.PoisResult) -> GeoJSONFeatureCollection {
  GeoJSONFeatureCollection(
    features: (result.pois ?? []).enumerated().map { index, poi in
      GeoJSONFeature(
        geometry: pointOrNil(poi.point),
        properties: featureProperties(
          ("category", textProperty(poi.category?.rawValue)),
          ("distanceMeters", numberProperty(poi.distanceMeters)),
          ("elevation", numberProperty(poi.elevation)),
          ("name", textProperty(poi.name)),
          (featureColorProperty, .string(poiResultPointColor)),
          (featureIndexProperty, numberProperty(index)),
          (featureKindProperty, "poi")))
    })
}
