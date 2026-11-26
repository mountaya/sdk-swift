import MountayaClient

/// UnitPreferences is how a reader wants measurements stated: the language they read, and four
/// preferences the wire carries, each independent of the others. Every formatter reads its own:
/// an imperial length beside a Celsius scale renders its temperatures in Celsius, since
/// temperature is never derived from length.
///
/// A preference the contract adds after this build, or one stored before it, reads as the default
/// its formatter names: an unknown system is metric, an unknown pace per time, an unknown slope
/// unit degrees and an unknown scale Celsius, so a formatter states it rather than failing.
///
/// Two are equal where every field is spelled with the same scalars.
public struct UnitPreferences: Sendable, Hashable {
  /// language is the reader's language, a BCP 47 language tag such as `fr-CA`: it chooses the
  /// digits, the decimal mark and the words around a number. An underscore parts subtags as a
  /// hyphen does, and a value that is no language tag reads as English. Always the caller's, never
  /// a platform's default.
  public var language: String
  /// length is the measurement system lengths are stated in: kilometers and meters, or miles and
  /// feet.
  public var length: RestSchema.UnitLength
  /// pace is whether a travel rate is stated per time, `km/h`, or per distance, `min/km`.
  public var pace: RestSchema.UnitPace
  /// slope is whether a slope is stated in degrees or as a percentage grade.
  public var slope: RestSchema.UnitSlope
  /// temperature is the scale a temperature is stated in.
  public var temperature: RestSchema.UnitTemperature

  /// Creates a reader's preferences, each one the reader leaves unsaid the metric, per-time,
  /// degrees and Celsius default.
  public init(
    language: String,
    length: RestSchema.UnitLength = .metric,
    pace: RestSchema.UnitPace = .perTime,
    slope: RestSchema.UnitSlope = .degrees,
    temperature: RestSchema.UnitTemperature = .celsius
  ) {
    self.language = language
    self.length = length
    self.pace = pace
    self.slope = slope
    self.temperature = temperature
  }

  /// Two preferences are equal where every field is spelled with the same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.language, rhs.language) && sameText(lhs.length, rhs.length)
      && sameText(lhs.pace, rhs.pace) && sameText(lhs.slope, rhs.slope)
      && sameText(lhs.temperature, rhs.temperature)
  }

  /// hash feeds every field.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(language)
    hasher.combine(length)
    hasher.combine(pace)
    hasher.combine(slope)
    hasher.combine(temperature)
  }
}
