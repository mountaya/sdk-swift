/// MeasureProbe records every line `cumulativeMeters(_:)` measures while a test holds it, so a
/// budget test reads what a burst of work costs in measurements (`route-measure` in the contract's
/// `sdk/hot-paths.yaml`): a measurement is a haversine per vertex of the whole line, and a
/// navigation that measured its route on every fix would pay for its whole length again on the
/// path every fix takes.
///
/// No measurement is recorded anywhere until a test installs a probe through `$current`, for the
/// work of its own task alone, so two tests running at once record apart. Without one, a
/// measurement reads one task-local value, nil, and allocates nothing.
///
/// It is Sendable: the lines it records sit behind a lock, since the child tasks of the test's
/// task inherit the probe and may record through it at once.
final class MeasureProbe: Sendable {
  /// current is the probe the running task holds, nil unless a test installs one.
  @TaskLocal static var current: MeasureProbe?

  private let measured = Locked<[[[Double]]]>([])

  /// lines is every line measured while the probe was held, in the order it was measured.
  var lines: [[[Double]]] {
    measured.value
  }

  /// record records a measurement of `line`.
  func record(_ line: [[Double]]) {
    measured.withLock { $0.append(line) }
  }
}
