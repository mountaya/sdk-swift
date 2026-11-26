import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("segmentRowTarget")
struct SegmentRowTargetTests {
  @Test("a row pins the sample nearest its leg's end, the earlier of two, and lights its leg")
  func target() {
    let valley = segmentRowTarget(segmentRow("valley", from: 0, to: 400), series: rowTargetSeries)
    #expect(valley.lngLat == [6, 45.0045])
    #expect(
      valley.stretch == lineBetween(rowTargetSeries.points, from: 0, to: 400))
    // 625 m stands halfway between the samples at 500 and 750 m: the earlier is pinned.
    let approach = segmentRowTarget(
      segmentRow("approach", from: 0, to: 625), series: rowTargetSeries)
    #expect(approach.lngLat == [6, 45.0045])
    #expect(segmentRowTarget(nil, series: rowTargetSeries) == MapTarget())
  }
}
