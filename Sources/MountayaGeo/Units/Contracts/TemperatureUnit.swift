/// TemperatureUnit is a scale a temperature is read on, each spelled by its contract unit id, the
/// ECMA-402 identifier and the value of the reader's temperature preference.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum TemperatureUnit: String, CaseIterable, Sendable {
  /// celsius is degrees Celsius.
  case celsius
  /// fahrenheit is degrees Fahrenheit: nine fifths of the Celsius reading, plus 32.
  case fahrenheit

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
