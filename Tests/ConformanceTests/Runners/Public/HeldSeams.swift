import Foundation
import MountayaClient

/// HeldSeams is every seam a runner off a simulation hands a client in place of the platform's, so
/// no conformance runner reads the machine's clock, calendar or random source: a clock whose time
/// never moves, a wall clock reading one instant, and draws of the harness's own. A runner on a
/// simulation hands its client the simulation's clock instead, `Scripted.client(_:exchange:)`.
enum HeldSeams {
  /// epoch is the instant the wall clock reads, 2026-03-14T09:26:53Z, the instant the fixtures'
  /// own records name.
  static let epoch = Date(timeIntervalSince1970: 1_773_480_413)

  /// wallClock is a wall clock reading `epoch`.
  static let wallClock = PublicRunners.FixedWallClock(now: epoch)

  /// forGood suspends until the task is cancelled, then throws `CancellationError`: a wait that
  /// reads no clock.
  static func forGood() async throws {
    let (never, held) = AsyncStream<Never>.makeStream()
    for await _ in never {}
    withExtendedLifetime(held) {}
    try Task.checkCancellation()
  }

  /// Still is a clock whose time never moves: a wait for no time ends at once, and any other only
  /// once its task is cancelled, so no attempt's budget runs out on the machine's time and an
  /// attempt a script holds waits for the step that settles it.
  struct Still: Clock {
    /// Instant is an offset from the clock's one moment, which no time passes after.
    struct Instant: InstantProtocol {
      /// offset is how long after the clock's moment the instant lies.
      var offset: Duration

      /// advanced returns the instant `duration` later.
      func advanced(by duration: Duration) -> Instant {
        Instant(offset: offset + duration)
      }

      /// duration returns how long it is from this instant to `other`.
      func duration(to other: Instant) -> Duration {
        other.offset - offset
      }

      /// One instant is before another where its offset is smaller.
      static func < (lhs: Instant, rhs: Instant) -> Bool {
        lhs.offset < rhs.offset
      }
    }

    /// now is the clock's one moment.
    var now: Instant {
      Instant(offset: .zero)
    }

    /// minimumResolution is no time at all.
    var minimumResolution: Duration {
      .zero
    }

    /// sleep returns at once for a deadline already reached, and otherwise suspends until the
    /// task is cancelled, then throws `CancellationError`.
    func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
      try Task.checkCancellation()
      guard deadline.offset > .zero else { return }
      try await HeldSeams.forGood()
    }
  }

  /// Draws draws zero before every wait, so a repeat waits no time, and answers one key, the
  /// harness's own, wherever a key is drawn.
  struct Draws: RandomSource {
    /// key is the one key every draw answers.
    static let key = UUID(uuid: (0, 0, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, 1))

    /// unitDraw answers zero.
    func unitDraw() -> Double {
      0
    }

    /// cryptographicUuid answers the harness's one key.
    func cryptographicUuid() -> UUID? {
      Self.key
    }
  }

  /// client is a client of `credential` sending through `exchange` to `baseUrls`, under `retry`,
  /// every other seam the harness's own.
  static func client(
    credential: Credential, baseUrls: BaseURLs = .standard, retry: RetryPolicy = .standard,
    exchange: any HTTPExchange
  ) throws(MountayaError) -> Mountaya {
    try Mountaya(
      credential: credential, baseUrls: baseUrls, retry: retry, exchange: exchange,
      clock: Still(), random: Draws(), wallClock: wallClock)
  }
}
