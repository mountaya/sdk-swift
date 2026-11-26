import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("searchFocus")
struct SearchFocusTests {
  @Test("a centre within range is sent as written, -0 and 180 included")
  func asWritten() {
    #expect(searchFocus([6.8652, 45.9237]) == [6.8652, 45.9237])
    #expect(searchFocus([180, 0]) == [180, 0])
    #expect(searchFocus([-180, 0]) == [-180, 0])
    #expect(searchFocus([-0.0, 0]).map { $0[0].sign } == .minus)
  }

  @Test("a centre counted past the antimeridian is brought back by whole turns")
  func wrapped() {
    #expect(searchFocus([197.5, 21.3]) == [-162.5, 21.3])
    #expect(searchFocus([-190, 10]) == [170, 10])
    #expect(searchFocus([366.5, 45]) == [6.5, 45])
  }

  @Test("a latitude past a pole is held at the pole")
  func poles() {
    #expect(searchFocus([6.5, 95]) == [6.5, 90])
    #expect(searchFocus([6.5, -100]) == [6.5, -90])
  }

  @Test("a centre that names no point ranks around nothing, an altitude left out")
  func noPoint() {
    #expect(searchFocus([.nan, 45.9237]) == nil)
    #expect(searchFocus([6.5, .infinity]) == nil)
    #expect(searchFocus([6.5]) == nil)
    #expect(searchFocus([]) == nil)
    #expect(searchFocus([6.5, 45, 1200]) == [6.5, 45])
  }
}
