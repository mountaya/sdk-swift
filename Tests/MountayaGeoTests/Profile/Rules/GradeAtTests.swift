import Testing

@testable import MountayaGeo

@Suite("gradeAt")
struct GradeAtTests {
  private let bend = samples((0, 1_000), (40, 1_000), (240, 1_040), (440, 1_000))

  @Test("a steady climb reads its slope, a descent reads negative")
  func slopes() {
    let climb = samples((0, 1_000), (200, 1_020), (400, 1_040), (600, 1_060))
    #expect(isClose(gradeAt(climb, distance: 300) ?? .nan, 5.710593137499643, within: 1e-9))
    #expect(isClose(gradeAt(bend, distance: 400) ?? .nan, -11.309932474020215, within: 1e-9))
  }

  @Test("a window straddling a bend reads across it")
  func bendReading() {
    #expect(gradeAt(bend, distance: 240) == 0)
  }

  @Test("near either end the window is cut to the curve")
  func cut() {
    #expect(isClose(gradeAt(bend, distance: 10) ?? .nan, 3.8140748342903543, within: 1e-9))
    #expect(isClose(gradeAt(bend, distance: 489) ?? .nan, -11.30993247402272, within: 1e-9))
  }

  @Test("a window holding no length of the curve reads none")
  func none() {
    #expect(gradeAt(bend, distance: 490) == nil)
    #expect(gradeAt(bend, distance: -500) == nil)
    #expect(gradeAt(samples((0, 1_000)), distance: 0) == nil)
    #expect(gradeAt([], distance: 0) == nil)
    #expect(gradeAt(bend, distance: .nan) == nil)
  }
}
