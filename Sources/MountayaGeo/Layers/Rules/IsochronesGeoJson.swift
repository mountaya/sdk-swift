import MountayaClient

/// isochroneRamp is the sequential scale isochrone bands fill from, the nearest band palest, so the
/// eye goes to the dark edge, the limit of reach. A band past the last stop takes the ramp again
/// from the first, which is visibly wrong rather than subtly so.
public let isochroneRamp = ["#c5f6fa", "#99e9f2", "#66d9e8", "#3bc9db", "#22b8cf", "#15aabf"]

/// isochroneColor is the fill of the isochrone band at `index` of an answer, its place counted from
/// 0 (`geo.layers.isochrone-color`): `isochroneRamp`'s colour there, the ramp taken again from its
/// first stop past its last, so the seventh band takes the first stop, and the first stop for an
/// index below zero, which is no place in an answer. Keyed by the band's place, never its value, so
/// three bands of a walk and three of a drive look alike.
public func isochroneColor(_ index: Int) -> String {
  guard index >= 0 else { return isochroneRamp[0] }
  return isochroneRamp[index % isochroneRamp.count]
}

/// isochronesGeoJson draws `result`'s bands, one polygon feature each in the order the answer holds
/// them, which is the order they nest in, back to front: properties `area`, `center`,
/// `reachFactor` and `value`, `null` where the band states none, and `mtyaColor`
/// (`isochroneColor(_:)` of its place), `mtyaIndex` and `mtyaKind` `isochrone`.
public func isochronesGeoJson(_ result: DataSchema.IsochronesResult) -> GeoJSONFeatureCollection {
  GeoJSONFeatureCollection(
    features: (result.isochrones ?? []).enumerated().map { index, band in
      GeoJSONFeature(
        geometry: band.geometry,
        properties: featureProperties(
          ("area", numberProperty(band.area)),
          ("center", numbersProperty(band.center)),
          ("reachFactor", numberProperty(band.reachFactor)),
          ("value", numberProperty(band.value)),
          (featureColorProperty, .string(isochroneColor(index))),
          (featureIndexProperty, numberProperty(index)),
          (featureKindProperty, "isochrone")))
    })
}
