import Testing

@testable import MountayaGeo

@Suite("accuracyBounds")
struct AccuracyBoundsTests {
  private static func near(_ actual: [Double], _ expected: [Double]) -> Bool {
    actual.count == expected.count
      && zip(actual, expected).allSatisfy { abs($0 - $1) <= 1e-9 }
  }

  @Test("the box reaches the radius over the circumference either side, wider in longitude")
  func boxes() {
    #expect(
      Self.near(
        accuracyBounds([-73.9749, 40.7736], radiusMeters: 100),
        [-73.976086214142, 40.772701684716, -73.973713785858, 40.774498315284]))
    #expect(
      Self.near(
        accuracyBounds([0, 0], radiusMeters: 1000),
        [-0.008983152841, -0.008983152841, 0.008983152841, 0.008983152841]))
    #expect(
      Self.near(
        accuracyBounds([25.72, 70.98], radiusMeters: 500),
        [25.706217853745, 70.975508423579, 25.733782146255, 70.984491576421]))
    #expect(
      Self.near(
        accuracyBounds([-70.65, -33.45], radiusMeters: 2000),
        [-70.671532853324, -33.467966305682, -70.628467146676, -33.432033694318]))
  }

  @Test("a fix by the antimeridian keeps its east edge past it, and no accuracy is the position")
  func edges() {
    #expect(
      Self.near(
        accuracyBounds([179.9995, -16.5], radiusMeters: 100),
        [179.998563103051, -16.500898315284, 180.000436896949, -16.499101684716]))
    #expect(accuracyBounds([6.86, 45.83], radiusMeters: 0) == [6.86, 45.83, 6.86, 45.83])
  }

  @Test("nothing is refused, and a fix is framed at zoom 16 at most")
  func unknowns() {
    let short = accuracyBounds([6.86], radiusMeters: 100)
    #expect(short[1].isNaN && short[3].isNaN, "\(short)")
    let unknown = accuracyBounds([6.86, 45.83], radiusMeters: .nan)
    #expect(unknown.allSatisfy { $0.isNaN }, "\(unknown)")
    #expect(locateMaxZoom == 16)
  }
}
