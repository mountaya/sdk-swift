import Testing

@testable import MountayaGeo

@Suite("downsampleElevation")
struct DownsampleElevationTests {
  private func points(_ count: Int) -> [ElevationPoint] {
    (0..<count).map {
      ElevationPoint(distance: Double($0), elevation: Double($0), lngLat: [0, 0], index: $0)
    }
  }

  private func kept(_ count: Int, maxPoints: Int) -> [Int] {
    downsampleElevation(points(count), maxPoints: maxPoints).map { Int($0.elevation) }
  }

  @Test("each slot keeps the nearest sample, and both ends are kept")
  func nearest() {
    #expect(kept(7, maxPoints: 4) == [0, 2, 4, 6])
    #expect(kept(7, maxPoints: 6) == [0, 1, 2, 4, 5, 6])
  }

  @Test("a slot halfway between two samples keeps the later")
  func halfway() {
    #expect(kept(6, maxPoints: 5) == [0, 1, 3, 4, 5])
    // 249 × 503 / 498 is 251.5 exactly, which a floating-point stride reads as 251.49999999999997.
    #expect(kept(504, maxPoints: 499)[249] == 252)
  }

  @Test("the kept samples are renumbered")
  func renumbered() {
    #expect(downsampleElevation(points(7), maxPoints: 4).map(\.index) == [0, 1, 2, 3])
  }

  @Test("a ceiling under two, or one the series is within, keeps every sample")
  func keepsEverySample() {
    #expect(kept(7, maxPoints: 1) == Array(0..<7))
    #expect(kept(7, maxPoints: -3) == Array(0..<7))
    #expect(kept(7, maxPoints: 7) == Array(0..<7))
    #expect(kept(0, maxPoints: 4).isEmpty)
  }
}
