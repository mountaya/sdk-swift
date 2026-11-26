import Testing

@testable import MountayaGeo

@Suite("assignDistinctColors")
struct AssignDistinctColorsTests {
  @Test("a batch is spread evenly over the colours left")
  func spread() {
    #expect(assignDistinctColors(3, reserved: []) == ["#fa5252", "#4c6ef5", "#40c057"])
    #expect(
      assignDistinctColors(3, reserved: ["#fa5252", "#e64980"])
        == ["#be4bdb", "#228be6", "#40c057"])
  }

  /// A reserved colour is compared with the ASCII capitals folded, and nothing else folded.
  @Test("a reserved colour is avoided whatever its case")
  func reservedCase() {
    #expect(assignDistinctColors(1, reserved: ["#FA5252"]) == ["#e64980"])
    #expect(
      assignDistinctColors(1, reserved: ["#FA5252"], palette: ["#FA5252", "#ffffff"])
        == ["#ffffff"])
  }

  @Test("more colours than the palette holds repeat, and a count under one is none")
  func counts() {
    #expect(
      assignDistinctColors(14, reserved: []) == livelyPalette + livelyPalette.prefix(2))
    #expect(assignDistinctColors(0, reserved: []).isEmpty)
    #expect(assignDistinctColors(-3, reserved: []).isEmpty)
  }

  @Test("a palette every colour of which is reserved is read whole")
  func allReserved() {
    let two = ["#000000", "#ffffff"]
    #expect(assignDistinctColors(2, reserved: two, palette: two) == ["#000000", "#ffffff"])
    #expect(assignDistinctColors(1, reserved: [], palette: []) == ["#fa5252"])
  }
}
