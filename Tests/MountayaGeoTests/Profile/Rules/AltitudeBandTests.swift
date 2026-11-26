import Testing

@testable import MountayaGeo

@Suite("altitudeBand")
struct AltitudeBandTests {
  private let points = samples((0, 1_000), (100, 1_200), (200, 1_100))

  @Test("the band holds the samples within and the curve at both ends")
  func band() {
    #expect(
      altitudeBand(points, from: 0, to: 200).map { [$0.lowest, $0.highest] } == [1_000, 1_200])
    #expect(
      altitudeBand(points, from: 25, to: 150).map { [$0.lowest, $0.highest] } == [1_050, 1_200])
    #expect(
      altitudeBand(points, from: 150, to: 175).map { [$0.lowest, $0.highest] } == [1_125, 1_150])
  }

  @Test("a stretch the samples do not reach has no band")
  func noBand() {
    #expect(
      altitudeBand(points, from: 200, to: 900).map { [$0.lowest, $0.highest] } == [1_100, 1_100])
    #expect(altitudeBand(points, from: 300, to: 900) == nil)
    #expect(altitudeBand([], from: 0, to: 1) == nil)
    #expect(altitudeBand(points, from: .nan, to: 100) == nil)
  }
}
