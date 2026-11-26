import Testing

@testable import MountayaGeo

@Suite("ElevationEncoding")
struct ElevationEncodingTests {
  @Test("an encoding is compared whole, and one this build never saw reads as itself")
  func open() {
    #expect(ElevationEncoding(rawValue: "mapbox") == .mapbox)
    #expect(ElevationEncoding(rawValue: "Mapbox") != .mapbox)
    #expect(ElevationEncoding(rawValue: "custom").rawValue == "custom")
    #expect(
      ElevationEncoding.terrarium.hashValue == ElevationEncoding(rawValue: "terrarium").hashValue)
  }
}
