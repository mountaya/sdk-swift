import Testing

@testable import MountayaGeo

@Suite("InfoBand")
struct InfoBandTests {
  @Test("two bands are equal when they hold the same numbers and the same value, and hash alike")
  func equality() {
    let band = InfoBand(startKm: 0, endKm: 0.77, value: "asphalt")
    #expect(band == InfoBand(startKm: 0, endKm: 0.77, value: "asphalt"))
    #expect(band.hashValue == InfoBand(startKm: 0, endKm: 0.77, value: "asphalt").hashValue)
    #expect(band != InfoBand(startKm: -0.0, endKm: 0.77, value: "asphalt"))
    #expect(band != InfoBand(startKm: 0, endKm: 0.77, value: "gravel"))
    #expect(
      String(describing: band) == "InfoBand<String>(startKm: 0.0, endKm: 0.77, value: \"asphalt\")")
  }

  /// A number held as the value is compared as every number of the geo layer.
  @Test("a band of numbers compares them as the same numbers")
  func numbers() {
    #expect(
      InfoBand(startKm: 0, endKm: 1, value: Double.nan)
        == InfoBand(startKm: 0, endKm: 1, value: .nan))
    #expect(
      InfoBand(startKm: 0, endKm: 1, value: 0.0) != InfoBand(startKm: 0, endKm: 1, value: -0.0))
  }
}
