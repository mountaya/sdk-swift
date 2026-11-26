import Testing

@testable import MountayaGeo

@Suite("convertDataSize")
struct ConvertDataSizeTests {
  @Test("the kilo and mega names are decimal")
  func decimal() {
    #expect(convertDataSize(1, from: .byte, to: .bit) == 8)
    #expect(convertDataSize(1, from: .kilobyte, to: .byte) == 1_000)
    #expect(convertDataSize(1, from: .megabit, to: .bit) == 1_000_000)
    #expect(convertDataSize(240, from: .megabit, to: .megabyte) == 30)
    #expect(convertDataSize(1, from: .kilobyte, to: .megabit) == 0.008)
  }

  /// A mebibyte, the unit the contract states its body ceilings in, is not a megabyte.
  @Test("the kibi and mebi names are binary")
  func binary() {
    #expect(convertDataSize(4, from: .kibibyte, to: .byte) == 4_096)
    #expect(convertDataSize(25, from: .mebibyte, to: .byte) == 26_214_400)
    #expect(convertDataSize(1, from: .megabyte, to: .mebibyte) == 0.95367431640625)
    #expect(convertDataSize(1, from: .mebibyte, to: .megabyte) == 1.048576)
    #expect(convertDataSize(1, from: .mebibyte, to: .kibibyte) == 1_024)
  }

  @Test("a size in its own unit is returned as it is")
  func ownUnit() {
    for unit in DataSizeUnit.allCases {
      #expect(convertDataSize(0.1, from: unit, to: unit) == 0.1)
    }
  }
}
