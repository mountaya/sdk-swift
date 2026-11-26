import Testing

@testable import MountayaGeo

@Suite("DurationUnit")
struct DurationUnitTests {
  /// The ids are the contract's spellings, ECMA-402's where it names the unit, and a runner reads a
  /// fixture's unit by them, in the alphabetical order the cases are declared in.
  @Test("each unit is spelled by the contract's id, in the order of the ids")
  func ids() {
    #expect(DurationUnit.allCases.map(\.id) == ["day", "hour", "millisecond", "minute", "second"])
    #expect(DurationUnit.allCases.map(\.id) == DurationUnit.allCases.map(\.id).sorted())
  }
}
