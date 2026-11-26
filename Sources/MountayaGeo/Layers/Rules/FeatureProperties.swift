import MountayaClient

/// featureKindProperty is the property naming what a drawn Data API feature is: `isochrone`,
/// `suggestion`, `matrix-connector`.
public let featureKindProperty = "mtyaKind"

/// featureIndexProperty is the property holding a drawn feature's place in the answer it came from.
public let featureIndexProperty = "mtyaIndex"

/// featureColorProperty is the property holding the colour a drawn feature paints in, where its
/// kind is coloured.
public let featureColorProperty = "mtyaColor"

/// featureWidthProperty is the property holding the width a matrix connector draws at, in pixels.
public let featureWidthProperty = "mtyaWidth"

/// featureProperties is the properties of a feature, each member the datum states or `null` where
/// it states none. A key written twice keeps its last value.
func featureProperties(_ entries: (String, JSONValue)...) -> [String: JSONValue] {
  Dictionary(entries, uniquingKeysWith: { _, last in last })
}

/// numberProperty is a number as a property, `null` where the datum states none.
func numberProperty(_ value: Double?) -> JSONValue {
  value.map(JSONValue.number) ?? .null
}

/// numberProperty is a whole number as a property, `null` where the datum states none.
func numberProperty(_ value: Int?) -> JSONValue {
  value.map { .number(Double($0)) } ?? .null
}

/// textProperty is a text as a property, `null` where the datum states none.
func textProperty(_ value: String?) -> JSONValue {
  value.map(JSONValue.string) ?? .null
}

/// numbersProperty is a list of numbers as a property, an array, `null` where the datum states none.
func numbersProperty(_ values: [Double]?) -> JSONValue {
  values.map { .array($0.map(JSONValue.number)) } ?? .null
}

/// pointOrNil is a point at `position`, or no geometry where it names no place.
func pointOrNil(_ position: [Double]?) -> GeoJSONGeometry? {
  guard let position, namesPlace(position) else { return nil }
  return .point(GeoJSONPoint(coordinates: position))
}
