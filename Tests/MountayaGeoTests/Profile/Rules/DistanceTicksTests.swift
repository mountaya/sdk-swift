import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("distanceTicks")
struct DistanceTicksTests {
  private let metric = RestSchema.UnitLength.metric
  private let imperial = RestSchema.UnitLength.imperial

  @Test("the step is the smallest one, two or five at least the rough step")
  func step() {
    #expect(distanceTicks(from: 0, to: 42_195, length: metric).map(\.value) == [0, 10, 20, 30, 40])
    #expect(
      distanceTicks(from: 0, to: 100_000, length: metric, target: 3).map(\.value) == [0, 50, 100])
    #expect(
      distanceTicks(from: 0, to: 42_195, length: imperial).map(\.value) == [0, 5, 10, 15, 20, 25])
  }

  @Test("a metric stop lands on whole meters and carries the digits its step needs")
  func wholeMeters() {
    #expect(
      distanceTicks(from: 1_200, to: 1_900, length: metric) == [
        DistanceTick(value: 1.2, meters: 1_200, fractionDigits: 1),
        DistanceTick(value: 1.4, meters: 1_400, fractionDigits: 1),
        DistanceTick(value: 1.6, meters: 1_600, fractionDigits: 1),
        DistanceTick(value: 1.8, meters: 1_800, fractionDigits: 1),
      ])
    #expect(
      isClose(
        distanceTicks(from: 0, to: 42_195, length: imperial)[1].meters, 8_046.72, within: 1e-9))
  }

  @Test("a range given backwards is read in order")
  func backwards() {
    #expect(
      distanceTicks(from: 3_000, to: 9_000, length: metric)
        == distanceTicks(from: 9_000, to: 3_000, length: metric))
    #expect(distanceTicks(from: 9_000, to: 3_000, length: metric).count == 7)
  }

  @Test("a range of no width, or no number, or no stop asked, has no stops")
  func noStops() {
    #expect(distanceTicks(from: 500, to: 500, length: metric).isEmpty)
    #expect(distanceTicks(from: 0, to: 1_000, length: metric, target: 0).isEmpty)
    #expect(distanceTicks(from: 0, to: .nan, length: metric).isEmpty)
    #expect(distanceTicks(from: 0, to: .infinity, length: metric).isEmpty)
    #expect(defaultDistanceTickCount == 6)
  }

  /// A normalized step of exactly two or five keeps it; one above five is ten, a decade up.
  @Test("a step on the lattice is kept, and one above five is the next decade")
  func lattice() {
    let twos = distanceTicks(from: 0, to: 12_000, length: metric)
    #expect(twos[1].value - twos[0].value == 2)
    let fives = distanceTicks(from: 0, to: 30_000, length: metric)
    #expect(fives[1].value - fives[0].value == 5)
    #expect(distanceTicks(from: 0, to: 10_000, length: metric, target: 1).map(\.value) == [0, 10])
  }

  /// Past 2^53 a double counts no further multiple of a step; the axis ends rather than loop.
  @Test("a range so far out a double counts no further multiple ends its stops")
  func farOut() {
    let ticks = distanceTicks(from: 0x1p63, to: 0x1p63 + 4_096, length: metric)
    #expect(ticks.count <= 7)
  }
}
