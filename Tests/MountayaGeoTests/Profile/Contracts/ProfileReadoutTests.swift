import Testing

@testable import MountayaGeo

@Suite("ProfileReadout")
struct ProfileReadoutTests {
  @Test("two readouts are equal where their cells, grade and stretch are")
  func equality() {
    let trail = ProfileClass(from: 400, to: 600, color: "#e8590c", label: "Trail")
    let readout = ProfileReadout(
      cells: [ReadoutCell(stat: .distance, value: 400)], grade: 1.432, stretch: trail)
    #expect(
      readout
        == ProfileReadout(
          cells: [ReadoutCell(stat: .distance, value: 400)], grade: 1.432, stretch: trail))
    #expect(readout != ProfileReadout(cells: readout.cells, grade: nil, stretch: trail))
    #expect(readout != ProfileReadout(cells: readout.cells, grade: 1.432, stretch: nil))
    #expect(
      ProfileReadout(cells: [], grade: .nan, stretch: nil).hashValue
        == ProfileReadout(cells: [], grade: .nan, stretch: nil).hashValue)
  }
}
