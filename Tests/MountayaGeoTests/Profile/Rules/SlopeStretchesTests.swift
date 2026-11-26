import Testing

@testable import MountayaGeo

@Suite("slopeStretches")
struct SlopeStretchesTests {
  @Test("the buckets are the contract's")
  func buckets() {
    #expect(
      slopeBuckets.map(\.key) == ["steepDescent", "descent", "flat", "ascent", "steepAscent"])
    #expect(slopeBuckets.map(\.from) == [-.infinity, -10, -3, 3, 10])
    #expect(slopeBuckets.map(\.color) == ["#e8590c", "#f59f00", "#2f9e44", "#f59f00", "#e8590c"])
  }

  @Test("long stretches read their own slope, and neighbours of one bucket merge")
  func long() {
    let stretches = slopeStretches(samples((0, 1_000), (200, 1_000), (400, 1_040), (600, 1_080)))
    #expect(
      stretches == [
        ProfileClass(from: 0, to: 200, color: "#2f9e44", label: "flat"),
        ProfileClass(from: 200, to: 600, color: "#e8590c", label: "steepAscent"),
      ])
  }

  @Test("a stretch as long as the window reads its own slope")
  func asLong() {
    #expect(
      slopeStretches(samples((0, 1_000), (100, 1_000), (200, 1_030))).map(\.label)
        == ["flat", "steepAscent"])
  }

  @Test("dense samples read the grade over the window")
  func dense() {
    let points = samplesEvery25Meters(
      1_000, 1_000, 1_000, 1_000, 1_000, 1_001, 1_012, 1_001, 1_000, 1_000, 1_000, 1_000, 1_000)
    #expect(
      slopeStretches(points).map { "\($0.label) \($0.from) \($0.to)" }
        == [
          "flat 0.0 75.0", "ascent 75.0 100.0", "flat 100.0 175.0", "descent 175.0 200.0",
          "flat 200.0 300.0",
        ])
  }

  @Test(
    "fewer than two samples, or no bucket, has no stretch; a grade under every bucket takes the first"
  )
  func edges() {
    #expect(slopeStretches(samples((0, 1_000))).isEmpty)
    #expect(slopeStretches([]).isEmpty)
    #expect(slopeStretches(samples((0, 1_000), (200, 1_000)), buckets: []).isEmpty)
    let high = [SlopeBucket(from: 50, key: "cliff", color: "#000")]
    #expect(
      slopeStretches(samples((0, 1_000), (200, 1_000)), buckets: high).map(\.label) == ["cliff"])
  }

  private func samplesEvery25Meters(_ elevations: Double...) -> [ElevationPoint] {
    elevations.enumerated().map {
      ElevationPoint(
        distance: Double($0.offset) * 25, elevation: $0.element, lngLat: [0, 0], index: $0.offset)
    }
  }
}
