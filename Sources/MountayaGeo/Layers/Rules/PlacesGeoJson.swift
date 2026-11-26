import MountayaClient

/// placePointColor is the fill of a geocoded place's marker.
public let placePointColor = "#f59f00"

/// placesGeoJson draws `result`'s geocoded places, one point feature each in its order, no geometry
/// for one whose point names no place, so every feature keeps its index: properties `bounds`,
/// `category`, `label`, `layer` and `name`, `null` where the place states none, `mtyaColor`
/// `placePointColor`, `mtyaIndex` and `mtyaKind` `place`.
public func placesGeoJson(_ result: DataSchema.GeocodeResult) -> GeoJSONFeatureCollection {
  GeoJSONFeatureCollection(
    features: (result.places ?? []).enumerated().map { index, place in
      GeoJSONFeature(
        geometry: pointOrNil(place.point),
        properties: featureProperties(
          ("bounds", numbersProperty(place.bounds)),
          ("category", textProperty(place.category?.rawValue)),
          ("label", textProperty(place.label)),
          ("layer", textProperty(place.layer?.rawValue)),
          ("name", textProperty(place.name)),
          (featureColorProperty, .string(placePointColor)),
          (featureIndexProperty, numberProperty(index)),
          (featureKindProperty, "place")))
    })
}
