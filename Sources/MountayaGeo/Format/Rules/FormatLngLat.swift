/// formatLngLat writes a position, `[longitude, latitude]` as the wire orders it, for a reader:
/// latitude first with its hemisphere, then longitude with its own, each to four decimal places,
/// `45.9237°N 6.8652°E`.
///
/// A longitude is read as an angle: one from -180 to 180 is printed as written, and one a map
/// counted past the antimeridian is stated as the meridian it names, so 197.5 is `162.5000°W`. A
/// hemisphere is chosen after rounding, so a value that prints as zero takes the positive one. The
/// digits and the decimal point are the same in every language, the contract's one exemption from
/// the locale services, since a locale's decimal comma beside the comma that parts two coordinates
/// is ambiguous; no formatter writes them.
///
/// It answers nil for a position that names no place: short of a longitude or a latitude, or with
/// either not finite. A latitude is printed as written, past a pole included, and an altitude is
/// not printed.
public func formatLngLat(_ position: [Double]) -> String? {
  guard namesPlace(position) else { return nil }
  let longitude = wrapLongitudePastRange(position[0])
  return coordinate(position[1], positive: "N", negative: "S") + " "
    + coordinate(longitude, positive: "E", negative: "W")
}

/// coordinate writes one coordinate's magnitude to four places, the degree sign, and the
/// hemisphere its sign names once rounded.
private func coordinate(_ value: Double, positive: String, negative: String) -> String {
  let digits = fourDecimalPlaces(abs(value))
  let printsAsZero = digits.allSatisfy { $0 == "0" || $0 == "." }
  return digits + "\u{B0}" + (value < 0 && !printsAsZero ? negative : positive)
}
