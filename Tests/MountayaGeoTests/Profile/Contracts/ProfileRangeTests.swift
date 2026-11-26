import Testing

@testable import MountayaGeo

@Suite("ProfileRange")
struct ProfileRangeTests {
  @Test("two stretches are equal where both ends are the same numbers, and hash alike")
  func equality() {
    let range = ProfileRange(from: 200, to: 800)
    #expect(range == ProfileRange(from: 200, to: 800))
    #expect(range.hashValue == ProfileRange(from: 200, to: 800).hashValue)
    #expect(range != ProfileRange(from: 800, to: 200))
    #expect(ProfileRange(from: .nan, to: 1) == ProfileRange(from: .nan, to: 1))
    #expect(ProfileRange(from: 0, to: 1) != ProfileRange(from: -0.0, to: 1))
  }

  @Test("a stretch is a span its ends can be moved on")
  func span() {
    var span: any ProfileSpan = ProfileRange(from: 1, to: 2)
    span.from = 0
    #expect(span.from == 0 && span.to == 2)
  }
}
