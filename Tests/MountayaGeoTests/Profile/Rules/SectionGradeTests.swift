import Testing

@testable import MountayaGeo

@Suite("sectionGrade")
struct SectionGradeTests {
  @Test("a leg's average grade is its climb less its loss over its length")
  func grade() {
    let up = ItinerarySegmentRowMetrics(
      sectionDistance: 6_000, sectionAscent: 450, sectionDescent: 30)
    #expect(isClose(sectionGrade(up) ?? .nan, 4.004172940709388, within: 1e-12))
    let down = ItinerarySegmentRowMetrics(
      sectionDistance: 6_000, sectionAscent: 30, sectionDescent: 450)
    #expect(isClose(sectionGrade(down) ?? .nan, -4.004172940709388, within: 1e-12))
  }

  @Test("a missing figure or no length is no grade")
  func none() {
    #expect(
      sectionGrade(ItinerarySegmentRowMetrics(sectionDistance: 6_000, sectionAscent: 450)) == nil)
    #expect(
      sectionGrade(
        ItinerarySegmentRowMetrics(sectionDistance: 0, sectionAscent: 0, sectionDescent: 0))
        == nil)
    #expect(
      sectionGrade(
        ItinerarySegmentRowMetrics(sectionDistance: -5, sectionAscent: 0, sectionDescent: 0))
        == nil)
  }
}
