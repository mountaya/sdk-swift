import Testing

@testable import MountayaGeo

@Suite("SpeedUnit")
struct SpeedUnitTests {
  /// The ids are the contract's spellings, ECMA-402's where it names the unit, and a runner reads a
  /// fixture's unit by them, in the alphabetical order the cases are declared in.
  @Test("each unit is spelled by the contract's id, in the order of the ids")
  func ids() {
    #expect(
      SpeedUnit.allCases.map(\.id) == [
        "kilometer-per-hour", "meter-per-second", "mile-per-hour", "minute-per-kilometer",
        "minute-per-mile",
      ])
    #expect(SpeedUnit.allCases.map(\.id) == SpeedUnit.allCases.map(\.id).sorted())
  }
}
