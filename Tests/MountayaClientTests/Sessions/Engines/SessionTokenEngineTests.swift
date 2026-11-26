import Foundation
import Testing

@testable import MountayaClient

@Suite("SessionTokenEngine")
struct SessionTokenEngineTests {
  private static let now = Date(timeIntervalSince1970: 1_800_000_000)

  private struct FixedWallClock: WallClock {
    let now: Date
  }

  private struct MintFailed: Error {}

  /// Hops records every wait the engine asks for, and waits on until the wait is cancelled.
  private final class Hops: Sleeper {
    let asked = Locked<[Duration]>([])

    var now: Duration {
      .zero
    }

    func sleep(for duration: Duration) async throws {
      asked.withLock { $0.append(duration) }
      try await Task.sleep(for: .seconds(3600))
    }
  }

  /// Mints counts the mints, answering each with the next session it was given.
  private final class Mints: Sendable {
    let count = Locked(0)
    let sessions: [Result<RestSchema.Session, MintFailed>]

    init(_ sessions: [Result<RestSchema.Session, MintFailed>]) {
      self.sessions = sessions
    }

    func mint() throws -> RestSchema.Session {
      let index = count.withLock { count -> Int in
        defer { count += 1 }
        return count
      }
      return try sessions[min(index, sessions.count - 1)].get()
    }
  }

  private static func session(_ token: String, lifetime: TimeInterval, user: String? = "u1")
    -> RestSchema.Session
  {
    RestSchema.Session(expires_at: now.addingTimeInterval(lifetime), user_id: user, token: token)
  }

  private static func until(_ condition: @escaping @Sendable () -> Bool) async -> Bool {
    for _ in 0..<2000 {
      if condition() {
        return true
      }
      try? await Task.sleep(for: .milliseconds(5))
    }
    return false
  }

  /// AskedClock is a consumer's own clock: it records every wait it is asked for, and waits on
  /// until the wait is cancelled.
  private final class AskedClock: Clock, Sendable {
    struct Instant: InstantProtocol {
      var offset: Swift.Duration

      func advanced(by duration: Swift.Duration) -> Instant {
        Instant(offset: offset + duration)
      }

      func duration(to other: Instant) -> Swift.Duration {
        other.offset - offset
      }

      static func < (lhs: Instant, rhs: Instant) -> Bool {
        lhs.offset < rhs.offset
      }
    }

    let asked = Locked<[Swift.Duration]>([])

    var now: Instant {
      Instant(offset: .zero)
    }

    var minimumResolution: Swift.Duration {
      .nanoseconds(1)
    }

    func sleep(until deadline: Instant, tolerance: Swift.Duration?) async throws {
      asked.withLock { $0.append(deadline.offset) }
      try await Task.sleep(for: .seconds(3600))
    }
  }

  private static func engine(_ mints: Mints, sleeper hops: Hops) -> SessionTokenEngine {
    SessionTokenEngine(
      mint: { try mints.mint() }, wallClock: FixedWallClock(now: now), sleeper: hops)
  }

  @Test("an app's own clock and wall clock hold the refresh schedule, through the public seams")
  func publicSeams() async {
    let mints = Mints([.success(Self.session("sess_a", lifetime: 300))])
    let clock = AskedClock()
    let engine = SessionTokenEngine(
      mint: { try mints.mint() }, clock: clock, wallClock: FixedWallClock(now: Self.now))
    let subscription = engine.subscribe()

    // Five minutes left at the pinned instant: the next mint is armed a minute before the expiry.
    #expect(await Self.until { clock.asked.value == [.seconds(240)] })
    #expect(mints.count.value == 1)
    #expect(engine.snapshot.token == "sess_a")
    _ = subscription
  }

  @Test(
    "nothing is minted before a subscription, and one mints and reports the token, its user and expiry"
  )
  func mintsWhileSubscribed() async {
    let mints = Mints([.success(Self.session("sess_a", lifetime: 300))])
    let hops = Hops()
    let engine = Self.engine(mints, sleeper: hops)
    try? await Task.sleep(for: .milliseconds(20))
    #expect(mints.count.value == 0)

    let subscription = engine.subscribe()
    #expect(await Self.until { engine.snapshot.token == "sess_a" })
    #expect(engine.snapshot.userId == "u1")
    #expect(engine.snapshot.expiresAt == Self.now.addingTimeInterval(300))
    #expect(await Self.until { hops.asked.value == [.seconds(240)] })
    _ = subscription
  }

  @Test("a spent token and a failed mint wait the floor, and a failure keeps the token held")
  func spentAndFailed() async {
    let mints = Mints([.success(Self.session("sess_a", lifetime: -10)), .failure(MintFailed())])
    let hops = Hops()
    let engine = Self.engine(mints, sleeper: hops)
    let subscription = engine.subscribe()
    #expect(await Self.until { hops.asked.value == [.seconds(5)] })
    engine.refresh()

    #expect(await Self.until { engine.snapshot.error is MintFailed })
    #expect(engine.snapshot.token == "sess_a")
    #expect(!engine.snapshot.isMinting)
    _ = subscription
  }

  @Test("the last subscription ending parks the engine, and replacing the mint mints nothing")
  func parks() async {
    let mints = Mints([.success(Self.session("sess_a", lifetime: 300))])
    let hops = Hops()
    let engine = Self.engine(mints, sleeper: hops)
    let reader = Task {
      for await _ in engine.subscribe() {}
    }
    #expect(await Self.until { mints.count.value == 1 })
    engine.mint = { Self.session("sess_b", lifetime: 300) }
    reader.cancel()
    try? await Task.sleep(for: .milliseconds(50))

    #expect(mints.count.value == 1)
    #expect(engine.snapshot.token == "sess_a")
  }

  @Test("disabling clears the token, its user, its expiry and the last error, and stops minting")
  func disables() async {
    let mints = Mints([.success(Self.session("sess_a", lifetime: 300))])
    let engine = Self.engine(mints, sleeper: Hops())
    let subscription = engine.subscribe()
    #expect(await Self.until { engine.snapshot.token != nil })
    engine.disable()
    engine.refresh()
    try? await Task.sleep(for: .milliseconds(50))

    #expect(engine.snapshot == SessionSnapshot())
    #expect(mints.count.value == 1)
    engine.enable()
    #expect(await Self.until { mints.count.value == 2 })
    _ = subscription
  }

  /// Leaps lets each wait pass at once, moving the time it reads by the wait, until that time would
  /// pass `horizon`, and waits on after that until the wait is cancelled.
  private final class Leaps: Sleeper {
    let elapsed = Locked(Duration.zero)
    let asked = Locked<[Duration]>([])
    let horizon: Duration

    init(horizon: Duration) {
      self.horizon = horizon
    }

    var now: Duration {
      elapsed.value
    }

    func sleep(for duration: Duration) async throws {
      asked.withLock { $0.append(duration) }
      let passes = elapsed.withLock { elapsed -> Bool in
        guard elapsed + duration <= horizon else { return false }
        elapsed += duration
        return true
      }
      if !passes {
        try await Task.sleep(for: .seconds(3600))
      }
    }
  }

  /// LeapsClock reads a leap's time as the wall clock, from the pinned instant.
  private struct LeapsClock: WallClock {
    let leaps: Leaps

    var now: Date {
      let (seconds, attoseconds) = leaps.now.components
      return SessionTokenEngineTests.now.addingTimeInterval(
        TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18)
    }
  }

  /// A timeout the application set on its own call is a failed mint like any other, whatever error
  /// it arrives as, and is minted again on the engine's schedule (`sdk/SPEC.md` §6).
  @Test("a mint that fails or times out is minted again on the schedule of a spent token")
  func failedMintRepeated() async {
    struct Timeout: Error {}
    for ending in [MintFailed() as any Error, URLError(.timedOut), Timeout()] {
      let count = Locked(0)
      let leaps = Leaps(horizon: .seconds(60))
      let engine = SessionTokenEngine(
        mint: {
          let mint = count.withLock { count -> Int in
            count += 1
            return count
          }
          guard mint > 1 else { throw ending }
          return Self.session("sess_b", lifetime: 3600)
        },
        wallClock: LeapsClock(leaps: leaps),
        sleeper: leaps
      )
      let subscription = engine.subscribe()
      #expect(await Self.until { engine.snapshot.token == "sess_b" }, "\(ending)")
      #expect(count.value == 2, "\(ending)")
      #expect(leaps.asked.value.first == .seconds(5), "the floor, as a run of one spent token")
      _ = subscription
    }
  }

  @Test("a mint the platform's loader reports cancelled ends the run, as a cancellation does")
  func cancelledLoad() async {
    let count = Locked(0)
    let engine = SessionTokenEngine(
      mint: {
        count.withLock { $0 += 1 }
        throw URLError(.cancelled)
      },
      wallClock: FixedWallClock(now: Self.now),
      sleeper: Leaps(horizon: .seconds(60))
    )
    let subscription = engine.subscribe()
    #expect(await Self.until { count.value == 1 && !engine.snapshot.isMinting })
    try? await Task.sleep(for: .milliseconds(50))
    #expect(count.value == 1)
    #expect(engine.snapshot.error is URLError)
    _ = subscription
  }

  @Test("a mint that throws a cancellation is never repeated, and the next mint is a refresh's")
  func cancelledMint() async {
    let count = Locked(0)
    let engine = SessionTokenEngine(
      mint: {
        let mint = count.withLock { count -> Int in
          count += 1
          return count
        }
        switch mint {
        case 1: return Self.session("sess_a", lifetime: 300)
        case 2: throw CancellationError()
        default: return Self.session("sess_b", lifetime: 300)
        }
      },
      wallClock: FixedWallClock(now: Self.now),
      sleeper: Hops()
    )
    let subscription = engine.subscribe()
    #expect(await Self.until { engine.snapshot.token == "sess_a" })
    engine.refresh()
    #expect(await Self.until { count.value == 2 && !engine.snapshot.isMinting })
    try? await Task.sleep(for: .milliseconds(50))

    // `sdk-kotlin`'s snapshot alike: the token, its expiry and its user held, nothing minting,
    // and the cancellation the last error.
    #expect(count.value == 2)
    let held = engine.snapshot
    #expect(held.token == "sess_a")
    #expect(held.expiresAt == Self.now.addingTimeInterval(300))
    #expect(held.userId == "u1")
    #expect(held.isMinting == false)
    #expect(held.error is CancellationError)
    // The run that ended with the cancellation leaves room for the next one.
    engine.refresh()
    #expect(await Self.until { engine.snapshot.token == "sess_b" })
    #expect(count.value == 3)
    #expect(engine.snapshot.error == nil)
    _ = subscription
  }

  /// `sdk-kotlin`'s twin cancels the engine's scope; this engine has none, and its own
  /// cancellation is its last subscription ending.
  @Test("an engine whose last subscription ends leaves no mint running")
  func cancelledEngine() async {
    let started = Locked(0)
    let cancelled = Locked(0)
    let engine = SessionTokenEngine(
      mint: {
        started.withLock { $0 += 1 }
        do {
          try await Task.sleep(for: .seconds(3600))
        } catch {
          cancelled.withLock { $0 += 1 }
          throw error
        }
        return Self.session("sess_a", lifetime: 300)
      },
      wallClock: FixedWallClock(now: Self.now),
      sleeper: Hops()
    )
    let reader = Task {
      for await _ in engine.subscribe() {}
    }
    #expect(await Self.until { started.value == 1 })
    reader.cancel()

    #expect(await Self.until { cancelled.value == 1 })
    try? await Task.sleep(for: .milliseconds(50))
    #expect(started.value == 1)
    #expect(engine.snapshot.error == nil)
  }

  @Test("each subscription is a stream of its own, told the snapshot now and then each change")
  func subscriptions() async {
    let released = Locked(false)
    let engine = SessionTokenEngine(
      mint: {
        while !released.value {
          try await Task.sleep(for: .milliseconds(1))
        }
        return Self.session("sess_a", lifetime: 300)
      },
      wallClock: FixedWallClock(now: Self.now),
      sleeper: Hops()
    )
    let told = Locked<[[String?]]>([[], []])
    let subscriptions = [engine.subscribe(), engine.subscribe()]
    let readers = subscriptions.enumerated().map { index, subscription in
      Task {
        for await snapshot in subscription {
          told.withLock { $0[index].append(snapshot.token) }
        }
      }
    }
    #expect(await Self.until { told.value.allSatisfy { !$0.isEmpty } })
    released.withLock { $0 = true }

    #expect(await Self.until { told.value.allSatisfy { $0.last == "sess_a" } })
    #expect(told.value.allSatisfy { $0.first == .some(nil) })
    readers.forEach { $0.cancel() }
  }
}
