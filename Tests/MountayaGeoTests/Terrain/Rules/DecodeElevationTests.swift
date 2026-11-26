import Testing

@testable import MountayaGeo

@Suite("decodeElevation")
struct DecodeElevationTests {
  @Test("mapbox reads each channel by its own weight, from ten kilometres below sea level")
  func mapbox() {
    #expect(decodeElevation([0, 0, 0], encoding: .mapbox) == -10000)
    #expect(decodeElevation([1, 134, 160], encoding: .mapbox) == 0)
    #expect(decodeElevation([1, 134, 160], encoding: nil) == 0)
    #expect(decodeElevation([1, 180, 208, 255], encoding: .mapbox) == 1182.4000000000015)
  }

  @Test("terrarium reads blue as the fraction")
  func terrarium() {
    #expect(decodeElevation([128, 0, 0], encoding: .terrarium) == 0)
    #expect(decodeElevation([135, 42, 128], encoding: .terrarium) == 1834.5)
    #expect(decodeElevation([0, 0, 0], encoding: .terrarium) == -32768)
  }

  @Test("any other encoding, compared whole, and a pixel of fewer channels read no height")
  func none() {
    #expect(decodeElevation([1, 134, 160], encoding: ElevationEncoding(rawValue: "custom")) == nil)
    #expect(decodeElevation([1, 134, 160], encoding: ElevationEncoding(rawValue: "Mapbox")) == nil)
    #expect(decodeElevation([1, 134], encoding: .mapbox) == nil)
  }
}
