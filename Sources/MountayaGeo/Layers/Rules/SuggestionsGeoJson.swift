import MountayaClient

/// suggestionChosenColor is the colour the chosen suggested itinerary draws in.
public let suggestionChosenColor = "#2b8a3e"

/// suggestionAlternativeColor is the colour a suggested itinerary not chosen draws in, the neutral
/// one an unconfirmed draft takes.
public let suggestionAlternativeColor = "#868e96"

/// suggestionsGeoJson draws `result`'s suggested itineraries, one line feature each in the order
/// the answer holds them, best first: properties `chosen`, `distance`, `duration`, `seed` and
/// `summary`, `mtyaColor` `suggestionChosenColor` for the one at `chosen` and
/// `suggestionAlternativeColor` for every other, `mtyaIndex` and `mtyaKind` `suggestion`. The first
/// is chosen unless `chosen` names another, so a reader's pick redraws by its place rather than by
/// reordering the answer, and a `chosen` no suggestion holds chooses none.
public func suggestionsGeoJson(
  _ result: DataSchema.SuggestionsResult, chosen: Int = 0
) -> GeoJSONFeatureCollection {
  GeoJSONFeatureCollection(
    features: (result.routes ?? []).enumerated().map { index, route in
      GeoJSONFeature(
        geometry: route.geometry,
        properties: featureProperties(
          ("chosen", .bool(index == chosen)),
          ("distance", numberProperty(route.distance)),
          ("duration", numberProperty(route.duration)),
          ("seed", numberProperty(route.seed)),
          ("summary", textProperty(route.summary)),
          (
            featureColorProperty,
            .string(index == chosen ? suggestionChosenColor : suggestionAlternativeColor)
          ),
          (featureIndexProperty, numberProperty(index)),
          (featureKindProperty, "suggestion")))
    })
}
