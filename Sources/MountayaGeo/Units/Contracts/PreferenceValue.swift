import MountayaClient

/// PreferenceValue is a value a preference takes, the option of a preferences picker a press names
/// (`geo.units.preference-choices`), in the wire's own vocabulary.
///
/// Two are equal where they are of one preference and spell the same scalars.
public enum PreferenceValue: Sendable, Hashable {
  /// length is a measurement system.
  case length(RestSchema.UnitLength)
  /// pace is a form a travel rate takes.
  case pace(RestSchema.UnitPace)
  /// slope is a slope notation.
  case slope(RestSchema.UnitSlope)
  /// temperature is a temperature scale.
  case temperature(RestSchema.UnitTemperature)
  /// language is a language, which the map labels in too.
  case language(RestSchema.Language)

  /// field is the preference the value is one of.
  public var field: PreferenceField {
    switch self {
    case .length: .length
    case .pace: .pace
    case .slope: .slope
    case .temperature: .temperature
    case .language: .language
    }
  }

  /// rawValue is the value as the wire spells it, `per-distance`.
  public var rawValue: String {
    switch self {
    case .length(let value): value.rawValue
    case .pace(let value): value.rawValue
    case .slope(let value): value.rawValue
    case .temperature(let value): value.rawValue
    case .language(let value): value.rawValue
    }
  }

  /// Two values are equal where they are of one preference and spell the same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.field == rhs.field && sameText(lhs.rawValue, rhs.rawValue)
  }

  /// hash feeds the preference and the spelling.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(field)
    hasher.combine(rawValue)
  }
}
