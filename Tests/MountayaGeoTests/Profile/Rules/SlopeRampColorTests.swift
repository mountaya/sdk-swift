import Testing

@testable import MountayaGeo

@Suite("slopeRampColor")
struct SlopeRampColorTests {
  @Test("an ascent and a descent read two ramps, and level ground the first ascent stop")
  func colours() {
    #expect(slopeRampColor(0) == "#66bb6a")
    #expect(slopeRampColor(-0.0) == "#66bb6a")
    #expect(slopeRampColor(5) == "#ffb414")
    #expect(slopeRampColor(-5) == "#2297eb")
    #expect(slopeRampColor(-1) == "#65b8b0")
  }

  @Test("at or past the last stop the last colour holds, and no number is grey")
  func lastStop() {
    #expect(slopeRampColor(22) == "#b71c1c")
    #expect(slopeRampColor(.infinity) == "#b71c1c")
    #expect(slopeRampColor(-45) == "#0d47a1")
    #expect(slopeRampColor(.nan) == "#94a3b8")
  }

  /// Halfway from #66BB6A to #FFEB3B: red 0x66 + 0x99 / 2 is 178.5, which rounds up.
  @Test("a channel halfway between two whole numbers rounds up")
  func halfUp() {
    #expect(slopeRampColor(2.5) == "#b3d353")
  }

  @Test("the ramps are the contract's")
  func contract() {
    #expect(ascentSlopeRamp.map(\.degrees) == [0, 2, 3, 6, 11, 22])
    #expect(descentSlopeRamp.map(\.degrees) == [0, 2, 3, 6, 11, 22])
    #expect(ascentSlopeRamp.first == descentSlopeRamp.first)
  }
}
