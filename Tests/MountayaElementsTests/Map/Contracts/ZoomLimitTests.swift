import MountayaElements
import Testing

@Suite("ZoomLimit")
struct ZoomLimitTests {
  @Test("a limit is kept, released, or a zoom written as a number")
  func limits() {
    let whole: ZoomLimit = 8
    let fraction: ZoomLimit = 12.5
    #expect(whole == .zoom(8))
    #expect(fraction == .zoom(12.5))
    #expect(ZoomLimit.kept != .released)
    #expect(ZoomLimit.zoom(.nan) == .zoom(.nan))
    #expect(ZoomLimit.zoom(0) != .zoom(-0.0))
  }
}
