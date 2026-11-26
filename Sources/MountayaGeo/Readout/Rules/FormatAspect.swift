import MountayaClient

/// aspectSeparator stands between an aspect's bearing and its direction's word.
private let aspectSeparator = " · "

/// formatAspect writes the aspect a readout's terrain row states (`geo.readout.rows`,
/// `sdk/SPEC.md` §7): the bearing the slope faces, `degrees` clockwise from north, in whole degrees
/// as `formatSlope(_:units:)` writes an angle in `language`, beside `cardinalWord`, the reader's
/// word for the direction it faces, `123° · South-East`. It is the bearing alone where the word is
/// empty, and the empty string for a bearing that is no finite number.
package func formatAspect(_ degrees: Double, cardinalWord: String, language: String) -> String {
  var units = UnitPreferences(language: language)
  units.slope = .degrees
  let bearing = formatSlope(degrees, units: units)
  guard !bearing.isEmpty else { return "" }
  return cardinalWord.isEmpty ? bearing : bearing + aspectSeparator + cardinalWord
}
