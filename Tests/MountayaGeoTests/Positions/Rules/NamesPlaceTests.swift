import Testing

@testable import MountayaGeo

@Suite("namesPlace")
struct NamesPlaceTests {
  @Test("a longitude and a latitude name a place, with or without an altitude")
  func place() {
    #expect(namesPlace([6.8652, 45.9237]))
    #expect(namesPlace([6.8652, 45.9237, 1035]))
    #expect(namesPlace([6.8652, 45.9237, .nan]))
    // A value past the range is still a place: a rule reads it as an angle, or as written.
    #expect(namesPlace([190, 95]))
  }

  @Test("a position written short names no place")
  func short() {
    #expect(!namesPlace([]))
    #expect(!namesPlace([6.88]))
  }

  @Test("a longitude or a latitude that is not finite names no place")
  func notFinite() {
    #expect(!namesPlace([.nan, 45]))
    #expect(!namesPlace([6, .nan]))
    #expect(!namesPlace([.infinity, 45]))
    #expect(!namesPlace([6, -.infinity]))
  }
}
