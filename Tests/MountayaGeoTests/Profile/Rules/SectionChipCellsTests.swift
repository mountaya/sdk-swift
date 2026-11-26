import Testing

@testable import MountayaGeo

@Suite("sectionChipCells")
struct SectionChipCellsTests {
  private let leg = ItinerarySegmentRowMetrics(
    sectionDistance: 6_000, sectionAscent: 450, sectionDescent: 30)

  @Test("the default figures are the leg's length and climb")
  func defaults() {
    #expect(defaultSectionChipStats == [.distance, .ascent])
    #expect(sectionChipCells(leg).map(\.value) == [6_000, 450])
  }

  @Test("the figures in the order asked, a missing one and a missing grade taking no cell")
  func ordered() {
    #expect(sectionChipCells(leg, stats: [.grade, .distance]).map(\.stat) == [.grade, .distance])
    let partial = ItinerarySegmentRowMetrics(sectionDistance: 6_000, sectionAscent: 450)
    #expect(
      sectionChipCells(partial, stats: SectionChipStat.allCases).map(\.stat) == [
        .distance, .ascent,
      ])
    #expect(sectionChipCells(ItinerarySegmentRowMetrics(), stats: SectionChipStat.allCases).isEmpty)
  }
}
