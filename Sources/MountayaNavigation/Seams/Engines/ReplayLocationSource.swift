import MountayaGeo

/// ReplayLocationSource walks the route a navigation follows at a steady speed, as a traveller
/// would: a demo, a screen recording, or a test that drives an engine end to end with no device
/// and no simulated location.
///
/// When a route is followed it states the line's start at once, before `follow(_:)` or
/// `start(_:)` returns, so the navigation reads the walk's own start on the route that lands
/// rather than a position a walk before it left, and a walk started again on the route it walked
/// sets out from its start. Then, at every `interval` of its clock, it states the position
/// `metersPerSecond` times the time elapsed on the clock since the start, along the line as
/// `positionAtMeters(_:meters:)` places it, and it ends on the line's last position. It reads each
/// position off the route's measure, taken once as the route was followed, by a search over its
/// distances, so a tick measures nothing, however long the line (`replay-measure` in the contract's
/// `sdk/hot-paths.yaml`). Each position
/// is placed by the time elapsed rather than by a stride added at each wake, so a main actor too
/// busy to wake the walk on time delays a position, never the walk: the next one stands where the
/// speed has carried the traveller meanwhile. A new route is walked from its own start, a
/// navigation that follows none stops the walk, and a speed that is no number above zero, a line
/// of no length, or an interval of none stands at the start. A position the navigation refuses
/// ends the walk. The clock is a seam: by default the system's suspending clock, which stands still
/// while the device sleeps, as `sdk-dart`'s `Stopwatch` and `sdk-kotlin`'s `TimeSource.Monotonic`
/// do, so a walk on a device that slept in a pocket goes on from where it stood rather than jump
/// ahead by the time asleep; and a test's own where a test paces the walk.
///
/// It is bound to the main actor, as every source is, and states every position there.
@MainActor
public final class ReplayLocationSource: LocationSource {
  private let metersPerSecond: Double
  private let interval: Duration
  /// clock is what the walk is paced by and placed on.
  let clock: any Clock<Duration>
  private var deliver: (@MainActor ([Double]) throws -> Void)?
  private var route: FollowedRoute?
  private var walk: Task<Void, Never>?
  /// walks counts the walks begun and ended, so a walk whose start brought a stop or another walk
  /// about walks no further.
  private var walks: UInt64 = 0

  /// Creates a source that walks each route followed at `metersPerSecond`, stating a position at
  /// every `interval` of `clock`, the system's suspending clock where none is given.
  public init(
    metersPerSecond: Double,
    interval: Duration = .seconds(1),
    clock: any Clock<Duration> = SuspendingClock()
  ) {
    self.metersPerSecond = metersPerSecond
    self.interval = interval
    self.clock = clock
  }

  deinit {
    // A source let go of walks no further.
    walk?.cancel()
  }

  /// start begins walking the route followed, from its start, and every route followed after it.
  public func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {
    guard self.deliver == nil else { return }
    self.deliver = deliver
    walkLine()
  }

  /// stop ends the walk: nothing more is stated until the next `start(_:)`.
  public func stop() {
    deliver = nil
    walks &+= 1
    walk?.cancel()
    walk = nil
  }

  /// follow walks `route` from its start, or ends the walk where the navigation follows none.
  public func follow(_ route: FollowedRoute?) {
    self.route = route
    walkLine()
  }

  /// walkLine walks the line of the route held from its start, stated at once, then in a task of
  /// its own, ending any walk before.
  private func walkLine() {
    walk?.cancel()
    walk = nil
    walks &+= 1
    guard let deliver, let route else { return }
    let walking = walks
    let task = Self.walking(
      route, metersPerSecond: metersPerSecond, interval: interval, on: clock, deliver: deliver
    ) { [weak self] in self?.walks == walking }
    // The start's reading may have stopped the source, or begun a walk of another line.
    if walks == walking {
      walk = task
    } else {
      task?.cancel()
    }
  }

  /// walking states the start of `route`'s line at once, then answers the task that walks it on
  /// at `metersPerSecond` on `clock`, stating at every `interval` the position the time elapsed
  /// since the start has carried the traveller to, until the line's end. It answers nil where the
  /// walk ends at its start: the start refused, the walk no longer `isCurrent` once its start was
  /// read, or a walk that goes nowhere. The line's length and every position are read off the
  /// route's measure, which the line's own readings, `routeLengthMeters(_:)` and
  /// `positionAtMeters(_:meters:)`, answer to the last digit, and nothing is measured again.
  private static func walking<Walking: Clock<Duration>>(
    _ route: FollowedRoute, metersPerSecond: Double, interval: Duration, on clock: Walking,
    deliver: @escaping @MainActor ([Double]) throws -> Void,
    isCurrent: @escaping @MainActor () -> Bool
  ) -> Task<Void, Never>? {
    let length = route.measured.last ?? 0
    // A speed that is no number above zero goes nowhere, nor does a line of no length or an
    // interval of none.
    let moves = metersPerSecond > 0 && metersPerSecond.isFinite && length > 0 && interval > .zero
    let started = clock.now
    do {
      try deliver(positionAtMeters(route, meters: 0))
    } catch {
      // A line whose positions name no place, which the engine refuses.
      return nil
    }
    guard moves, isCurrent() else { return nil }
    return Task {
      var walked = 0.0
      do {
        while walked < length {
          try await clock.sleep(for: interval)
          // A clock's sleep may end just as the walk is stopped, which the main actor saw first.
          try Task.checkCancellation()
          let elapsed = started.duration(to: clock.now)
          // A clock read back in time moves the traveller nowhere.
          walked = Swift.min(length, Swift.max(walked, metersPerSecond * seconds(elapsed)))
          try deliver(positionAtMeters(route, meters: walked))
        }
      } catch {
        // A cancelled walk, or a position the engine refuses.
        return
      }
    }
  }

  /// seconds is a duration as a number of seconds.
  private nonisolated static func seconds(_ duration: Duration) -> Double {
    let (seconds, attoseconds) = duration.components
    return Double(seconds) + Double(attoseconds) * 1e-18
  }
}
