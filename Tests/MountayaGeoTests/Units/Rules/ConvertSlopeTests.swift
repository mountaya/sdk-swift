import Testing

@testable import MountayaGeo

@Suite("convertSlope")
struct ConvertSlopeTests {
  /// Forty-five degrees is a hundred percent, not forty-five: a grade is the tangent in hundredths.
  @Test("a slope converts through the tangent")
  func tangent() {
    #expect(isClose(convertSlope(45, from: .degrees, to: .percentage), 100, within: 1e-12))
    #expect(convertSlope(100, from: .percentage, to: .degrees) == 45)
    #expect(
      isClose(convertSlope(0.1, from: .ratio, to: .degrees), 5.710593137499643, within: 1e-12))
    #expect(
      isClose(convertSlope(5.710593137499643, from: .degrees, to: .ratio), 0.1, within: 1e-15))
    #expect(convertSlope(0.08, from: .ratio, to: .percentage) == 8)
    #expect(convertSlope(8, from: .percentage, to: .ratio) == 0.08)
  }

  @Test("a descent keeps its sign")
  func descent() {
    #expect(
      isClose(convertSlope(-0.1, from: .ratio, to: .degrees), -5.710593137499643, within: 1e-12))
    #expect(convertSlope(-0.08, from: .ratio, to: .percentage) == -8)
  }

  /// A slope in its own unit is never taken through the tangent and back, which would cost digits.
  @Test("a slope in its own unit is returned as it is")
  func ownUnit() {
    for unit in SlopeUnit.allCases {
      #expect(convertSlope(33.3, from: unit, to: unit) == 33.3)
    }
  }
}
