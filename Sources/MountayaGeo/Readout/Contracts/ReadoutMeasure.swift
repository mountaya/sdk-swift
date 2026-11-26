/// ReadoutMeasure is what a readout's band is written in (`geo.readout.rows`), each by its
/// formatter of `geo.profile.unit-formatting`.
package enum ReadoutMeasure: String, Sendable, Hashable {
  case temperature
  case humidity
  case snowfall
  case distance
  case speed
}
