import Testing

@testable import MountayaGeo

@Suite("MeasureProbe")
struct MeasureProbeTests {
  private let line: [[Double]] = [[0, 0], [0.01, 0]]

  @Test("a probe records each line measured while it is held, in order, and nothing after")
  func recordsWhileHeld() {
    let probe = MeasureProbe()

    MeasureProbe.$current.withValue(probe) {
      _ = cumulativeMeters(line)
      _ = routeLengthMeters([[1, 1]])
    }
    _ = cumulativeMeters(line)

    #expect(probe.lines == [line, [[1, 1]]])
    #expect(MeasureProbe.current == nil, "no probe is held where no test installs one")
  }

  /// A probe is its own task's, so two tests running at once count apart.
  @Test("two tasks holding probes of their own record apart")
  func tasksRecordApart() async {
    let first = MeasureProbe()
    let second = MeasureProbe()

    async let one: Void = MeasureProbe.$current.withValue(first) {
      for _ in 0..<50 { _ = cumulativeMeters([[0, 0], [1, 1]]) }
      await Task.yield()
    }
    async let two: Void = MeasureProbe.$current.withValue(second) {
      for _ in 0..<20 { _ = cumulativeMeters([[2, 2]]) }
      await Task.yield()
    }
    _ = await (one, two)

    #expect(first.lines.count == 50 && first.lines.allSatisfy { $0 == [[0, 0], [1, 1]] })
    #expect(second.lines.count == 20 && second.lines.allSatisfy { $0 == [[2, 2]] })
  }
}
