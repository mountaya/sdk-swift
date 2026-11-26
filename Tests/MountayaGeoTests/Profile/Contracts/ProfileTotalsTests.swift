import Testing

@testable import MountayaGeo

@Suite("ProfileTotals")
struct ProfileTotalsTests {
  @Test("two totals are equal when every figure is, and hash alike")
  func equality() {
    let totals = ProfileTotals(
      distance: 7_117.5, ascent: 495, descent: 278, elevationMin: 1_035, elevationMax: 1_480,
      gradeMax: 14.1)
    let same = ProfileTotals(
      distance: 7_117.5, ascent: 495, descent: 278, elevationMin: 1_035, elevationMax: 1_480,
      gradeMax: 14.1)
    #expect(totals == same)
    #expect(totals.hashValue == same.hashValue)
    var unstated = totals
    unstated.ascent = nil
    #expect(totals != unstated)
    #expect(
      ProfileTotals(
        distance: 0, ascent: 0, descent: nil, elevationMin: nil, elevationMax: nil, gradeMax: nil)
        != ProfileTotals(
          distance: 0, ascent: -0.0, descent: nil, elevationMin: nil, elevationMax: nil,
          gradeMax: nil))
    #expect(
      String(
        describing: ProfileTotals(
          distance: 0, ascent: nil, descent: nil, elevationMin: nil, elevationMax: nil,
          gradeMax: nil))
        == "ProfileTotals(distance: 0.0, ascent: nil, descent: nil, elevationMin: nil, elevationMax: nil, gradeMax: nil)"
    )
  }
}
