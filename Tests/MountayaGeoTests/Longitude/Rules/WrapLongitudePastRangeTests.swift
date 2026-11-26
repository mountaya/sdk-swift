import Testing

@testable import MountayaGeo

@Suite("wrapLongitudePastRange")
struct WrapLongitudePastRangeTests {
  /// The wrap's arithmetic would cost these their last digits, and 180 would become -180.
  @Test("a longitude within the closed range keeps the digits it is written with")
  func keptAsWritten() {
    #expect(wrapLongitudePastRange(6.8652) == 6.8652)
    #expect(wrapLongitudePastRange(180) == 180)
    #expect(wrapLongitudePastRange(-180) == -180)
    #expect(wrapLongitudePastRange(-0.0).sign == .minus)
  }

  @Test("a longitude past the range is wrapped")
  func wrapped() {
    #expect(wrapLongitudePastRange(190) == -170)
    #expect(wrapLongitudePastRange(-180.5) == 179.5)
    #expect(wrapLongitudePastRange(540) == -180)
  }

  @Test("a longitude that is not finite wraps to NaN")
  func notFinite() {
    #expect(wrapLongitudePastRange(.infinity).isNaN)
    #expect(wrapLongitudePastRange(.nan).isNaN)
  }
}
