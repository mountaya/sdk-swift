import Testing

@testable import MountayaGeo

@Suite("DataSizeUnit")
struct DataSizeUnitTests {
  /// The ids are the contract's spellings, ECMA-402's where it names the unit, and a runner reads a
  /// fixture's unit by them, in the alphabetical order the cases are declared in.
  @Test("each unit is spelled by the contract's id, in the order of the ids")
  func ids() {
    #expect(
      DataSizeUnit.allCases.map(\.id) == [
        "bit", "byte", "kibibyte", "kilobit", "kilobyte", "mebibyte", "megabit", "megabyte",
      ])
    #expect(DataSizeUnit.allCases.map(\.id) == DataSizeUnit.allCases.map(\.id).sorted())
  }
}
