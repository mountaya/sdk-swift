import MountayaClient

/// elevationMinMeters is the least elevation a point of interest's second line states. An
/// OpenStreetMap `ele` tag missing or malformed reads as 0, and one near sea level tells nothing
/// apart, so below it the distance from the search's origin takes the place.
let elevationMinMeters = 100.0

/// distanceFigureCeiling is the first figure a distance is not stated at in its small unit: 1,000 m
/// reads `1.0 km`.
let distanceFigureCeiling = 1_000.0

/// The meters in a kilometer.
private let metersPerKilometer = 1_000.0

/// The grade of the scale every third path carries, which tells no path apart.
private let unremarkableGrade = "hiking"

/// describePlace is a geocoded place's second line under its title (`geo.search.describe`): what it
/// is, its category worded for the reader, then its region, then its country with its flag, each
/// left out where it repeats the title without regard to case, joined by a middle dot between
/// spaces. An address whose geocoder's label is another than its title reads as that label and its
/// country, and a country as what it is alone. `wording` words a category for the reader, and with
/// none a category reads as its English title.
public func describePlace(_ place: DataSchema.Place, wording: SearchWording = SearchWording())
  -> String
{
  let name = placeTitle(place, wording: wording)
  let primary = placeCategoryWord(place, wording: wording)
  let country = countryToken(place.country, name: place.countryName)
  let label = place.label ?? ""
  if place.category == .address {
    if !label.unicodeScalars.isEmpty, !sameText(label.lowercased(), name.lowercased()) {
      return country.isEmpty ? label : joinTokens(label, country)
    }
    return joinTokens(suppressIfMatchesName(primary, name: name), country)
  }
  if place.category == .country {
    return primary
  }
  return joinTokens(
    suppressIfMatchesName(primary, name: name), suppressIfMatchesName(place.region, name: name),
    country)
}

/// describePoi is a point of interest's second line under its title (`geo.search.describe`): its
/// category worded for the reader, then its elevation where it is at least 100 m and otherwise its
/// distance from the search's origin, then its town, else its region, and its country with its
/// flag, each left out where it repeats the title. Elevation leads, because three huts a kilometre
/// apart are told apart by their altitude. A figure is stated in `wording`'s units, rounded half away
/// from zero, and in metric with Latin digits where it states none: 1150 m away reads `1.2 km`.
public func describePoi(_ poi: DataSchema.POI, wording: SearchWording = SearchWording()) -> String {
  let name = poiTitle(poi, wording: wording)
  var figure = ""
  if let elevation = poi.elevation, elevation >= elevationMinMeters {
    figure = elevationToken(elevation, units: wording.units)
  } else if let distance = poi.distanceMeters, distance > 0 {
    figure = distanceToken(distance, units: wording.units)
  }
  return joinTokens(
    suppressIfMatchesName(poiCategoryWord(poi, wording: wording), name: name), figure,
    suppressIfMatchesName(poi.city ?? poi.region ?? "", name: name),
    countryToken(poi.country, name: poi.countryName))
}

/// describeWay is a way's second line under its title (`geo.search.describe`): its `highway` tag
/// worded for the reader, then its grade on the SAC scale where it is not the unremarkable
/// `hiking`, else its surface, worded as the whole token, `gravel surface`, then its town, else its
/// region, and its country with its flag, each left out where it repeats the title.
public func describeWay(_ way: DataSchema.Way, wording: SearchWording = SearchWording()) -> String {
  let name = wayTitle(way, wording: wording)
  var second = ""
  if let grade = way.sacScale, !grade.unicodeScalars.isEmpty, !sameText(grade, unremarkableGrade) {
    second = wordFor(.sacScale(grade), fallback: titleCase(grade), wording: wording)
  } else if let surface = way.surface, !surface.unicodeScalars.isEmpty {
    second = wordFor(
      .surface(surface), fallback: titleCase(surface).lowercased() + " surface", wording: wording)
  }
  return joinTokens(
    suppressIfMatchesName(highwayWord(way, wording: wording), name: name), second,
    suppressIfMatchesName(way.city ?? way.region ?? "", name: name),
    countryToken(way.country, name: way.countryName))
}

/// elevationToken is an elevation as a second line states it: whole meters, `3835 m`, or the
/// reader's units.
func elevationToken(_ meters: Double, units: UnitPreferences?) -> String {
  guard let units else {
    return "\(wholeFigure(roundHalfAwayFromZero(meters, fractionDigits: 0))) m"
  }
  return formatElevation(meters, units: units)
}

/// distanceToken is a distance as a second line states it: rounded to the nearest ten of its small
/// unit, since a search hit is not placed to the meter, and in the large unit to one decimal once
/// that figure reaches `distanceFigureCeiling`, so 995 m reads `1.0 km` and never `1000 m`. The
/// unit is chosen on the rounded figure. A distance that rounds to zero is nothing: `0 m` claims a
/// hit the reader stands on. With no units, meters and kilometers in Latin digits; with them, the
/// reader's system, language and digits. Every figure rounds half away from zero on its decimal
/// value.
func distanceToken(_ meters: Double, units: UnitPreferences?) -> String {
  let imperial = units.map { isImperial($0.length) } ?? false
  let small: LengthUnit = imperial ? .foot : .meter
  let tens =
    roundHalfAwayFromZero(convertLength(meters, from: .meter, to: small) / 10, fractionDigits: 0)
    * 10
  if tens == 0 { return "" }
  guard let units else {
    if tens < distanceFigureCeiling { return "\(wholeFigure(tens)) m" }
    let tenths = wholeFigure(
      roundHalfAwayFromZero(meters / metersPerKilometer, fractionDigits: 1) * 10)
    return "\(tenths / 10).\(tenths % 10) km"
  }
  let patterns = unitPatterns(units.language)
  if tens < distanceFigureCeiling {
    return formatMeasurement(
      tens, fractionDigits: 0, pattern: imperial ? patterns.foot : patterns.meter,
      language: units.language, patterns: patterns)
  }
  let large: LengthUnit = imperial ? .mile : .kilometer
  return formatMeasurement(
    convertLength(meters, from: .meter, to: large), fractionDigits: 1,
    pattern: imperial ? patterns.mile : patterns.kilometer, language: units.language,
    patterns: patterns, minimumFractionDigits: 1)
}

/// wholeFigure is a whole value as the 64-bit integer that writes it, held within the range of
/// one, `NaN` read as 0, as Kotlin's `roundToLong` reads it, where `Int64(_:)` would trap.
func wholeFigure(_ value: Double) -> Int64 {
  if value.isNaN { return 0 }
  // 2^63, the first double past the greatest Int64.
  if value >= 0x1p63 { return .max }
  if value < -0x1p63 { return .min }
  return Int64(value.rounded())
}
