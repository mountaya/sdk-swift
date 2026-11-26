import Foundation
import GateSupport

@testable import MountayaClient

extension InternalRunners {
  /// datesReviver decodes the case's answer as a generated type reads it and answers whether
  /// the value at `key` became an instant, and which one, written back in UTC.
  ///
  /// What a value becomes is decided by the type its property is declared as, never by its key
  /// or its look: a field the contract declares a date-time is read through `CodedTimestamp`, the
  /// wire form every such generated property reads through; any other string field is read as a
  /// `String`; and an object the contract leaves open is read as `JSONValue`, inside which a
  /// string stays a string. The answer carries the field at `key` and, where the case names
  /// `within`, the open object holding the same field, which is where the value is read.
  ///
  /// A declared value the anchor refuses fails the decode of the answer holding it, and is no
  /// instant. For every declared value that is no instant the answer says whether that answer
  /// decodes at all, `decodes`: false where it fails, true for a null and for a value an open
  /// object holds.
  static let datesReviver = Runner(id: "transport.dates.reviver", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    let key = try input.string(at: "key")
    let declared = try input.flag(at: "declared")
    let within = try input.optionalString(at: "within")
    guard let value = input["value"] else {
      throw FixtureError(description: "the input has no `value`")
    }
    var members = [OrderedJSON.Member(key: key, value: value)]
    if let within {
      members.append(
        OrderedJSON.Member(
          key: within, value: .object([OrderedJSON.Member(key: key, value: value)]))
      )
    }
    let answer = Data(OrderedJSON.object(members).serialized().utf8)
    let decoder = JSONDecoder()

    let date: Date?
    let decodes: Bool
    if let within {
      guard
        case .object(let open)? = try decoder.decode([String: JSONValue].self, from: answer)[within]
      else {
        throw FixtureError(description: "the open object did not decode as one")
      }
      guard case .string? = open[key] else {
        throw FixtureError(description: "the value inside the open object is not a string")
      }
      date = nil
      decodes = true
    } else if declared {
      let read = try? decoder.decode([String: CodedTimestamp?].self, from: answer)
      let field: CodedTimestamp? = read?[key] ?? nil
      date = field?.date
      decodes = read != nil
    } else {
      _ = try decoder.decode([String: String?].self, from: answer)
      date = nil
      decodes = true
    }
    var read = [
      OrderedJSON.Member(key: "instant", value: .bool(date != nil)),
      OrderedJSON.Member(
        key: "iso",
        value: date.map { .string(Timestamp.string(from: $0)) } ?? .null
      ),
    ]
    if declared, date == nil {
      read.append(OrderedJSON.Member(key: "decodes", value: .bool(decodes)))
    }
    return .value(.object(read))
  }

  /// sessionRefresh answers when the next mint happens, for a token's lifetime or for a run of
  /// spent tokens, after holding the rule's constants to the fixture's.
  ///
  /// A case that names `mintEndsWith` subscribes to a `SessionTokenEngine` whose first mint ends
  /// that way and answers whether the engine minted again within the refresh margin, its every wait
  /// passing at once on a wall clock that moves by it and never past the margin.
  ///
  /// A case that names `mints` plays that run on an engine over the same clock, every mint's call
  /// and end stamped, and answers the wait from each mint's end to the next one's call (`played`).
  ///
  /// A case that puts the machine to sleep is walked down hop by hop, as the engine walks it:
  /// each hop is armed from the wall clock, a timer runs only while the machine is awake and
  /// keeps the time it had left across the sleep, and the wall clock moves on through the
  /// sleep. The answer then carries how long the machine was awake before the hop that found
  /// the deadline passed.
  static let sessionRefresh = Runner(id: "transport.session.refresh", table: .internal) {
    fixture, fixtureCase in
    let constants = fixture.constants ?? .object([])
    let declared: [(String, Duration)] = [
      ("maxTimerMs", RefreshSchedule.maxTimer),
      ("minTimerMs", RefreshSchedule.minTimer),
      ("refreshMarginMs", RefreshSchedule.refreshMargin),
    ]
    for (key, value) in declared where try constants.number(at: key) != milliseconds(value) {
      throw FixtureError(description: "the fixture's `\(key)` is not the rule's")
    }

    let input = fixtureCase.input
    if let mints = input["mints"] {
      let endings = try (mints.elements ?? []).map { ending throws(FixtureError) -> String in
        guard let text = ending.stringValue else {
          throw FixtureError(description: "a mint's ending is not a string")
        }
        return text
      }
      return try await played(
        endings,
        lifetime: .milliseconds(try input.optionalNumber(at: "lifetimeMs") ?? 3_600_000)
      )
    }
    if let ending = try input.optionalString(at: "mintEndsWith") {
      return .value(
        .object([
          OrderedJSON.Member(key: "mintedAgain", value: .bool(try await mintsAgain(after: ending)))
        ])
      )
    }
    let plan: RefreshSchedule.Plan
    if let spent = try input.optionalInteger(at: "consecutiveSpent") {
      plan = RefreshSchedule.plan(consecutiveSpent: spent)
    } else {
      let lifetime = try input.optionalNumber(at: "lifetimeMs").map { Duration.milliseconds($0) }
      plan = RefreshSchedule.plan(lifetime: lifetime)
    }
    var members = [
      OrderedJSON.Member(key: "armed", value: .bool(plan.isArmed)),
      OrderedJSON.Member(key: "delayMs", value: .milliseconds(plan.delay)),
    ]
    if let sleepsAt = try input.optionalNumber(at: "sleepsAtMs") {
      let sleepsFor = Duration.milliseconds(try input.number(at: "sleepsForMs"))
      let awake = try awakeBeforeRefresh(
        delay: plan.delay,
        sleepsAt: .milliseconds(sleepsAt),
        sleepsFor: sleepsFor
      )
      members.append(OrderedJSON.Member(key: "awakeMsBeforeRefresh", value: .milliseconds(awake)))
    }
    return .value(.object(members))
  }

  /// Leap is a sleeper whose every wait passes at once, moving the time it reads by the wait, and
  /// waits for good once that time would pass its horizon, which a run may move, until its task is
  /// cancelled: it reads no clock of the machine's.
  final class Leap: Sleeper {
    let horizon: Locked<Duration>
    let elapsed = Locked(Duration.zero)

    init(horizon: Duration) {
      self.horizon = Locked(horizon)
    }

    var now: Duration {
      elapsed.withLock { $0 }
    }

    func sleep(for duration: Duration) async throws {
      let horizon = self.horizon.withLock { $0 }
      let passes = elapsed.withLock { elapsed -> Bool in
        guard elapsed + duration <= horizon else { return false }
        elapsed += duration
        return true
      }
      if !passes {
        try await HeldSeams.forGood()
      }
      try Task.checkCancellation()
    }
  }

  /// LeapWallClock reads a leap's time as the wall clock, from the epoch.
  struct LeapWallClock: WallClock {
    let leap: Leap

    var now: Date {
      Self.date(leap.now)
    }

    /// date is the instant a time on a leap stands for, from the epoch.
    static func date(_ time: Duration) -> Date {
      let (seconds, attoseconds) = time.components
      return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18)
    }
  }

  /// MintsSeen is what a run of mints is read by as it comes to rest: the mints called and ended,
  /// and the engine's snapshot.
  struct MintsSeen: Equatable {
    var calls: Int
    var ends = 0
    var snapshot: SessionSnapshot
  }

  /// MintEnding is the failure of the application's own the runner's first mint ends with where
  /// the case says it fails.
  struct MintEnding: Error {}

  /// mintsAgain subscribes to an engine whose first mint ends as `ending` says, and returns
  /// whether it called the mint again before the refresh margin passed: a failure of the
  /// application's own, the timeout the platform's loader raises for a call the application gave a
  /// timeout, `URLError.timedOut`, or Swift's `CancellationError`.
  private static func mintsAgain(after ending: String) async throws -> Bool {
    let error: any Error
    switch ending {
    case "failure": error = MintEnding()
    case "timeout": error = URLError(.timedOut)
    case "cancellation": error = CancellationError()
    default: throw FixtureError(description: "no mint ends with `\(ending)`")
    }
    let mints = Locked(0)
    let leap = Leap(horizon: RefreshSchedule.refreshMargin)
    let engine = SessionTokenEngine(
      mint: {
        let mint = mints.withLock { count -> Int in
          count += 1
          return count
        }
        guard mint > 1 else { throw error }
        return RestSchema.Session(
          expires_at: Date(timeIntervalSince1970: 3600), user_id: nil, token: "sess_again")
      },
      wallClock: LeapWallClock(leap: leap),
      sleeper: leap
    )
    let subscription = engine.subscribe()
    // The first mint has ended once its error is the snapshot's and nothing mints; a mint again
    // follows it at once, since every wait passes at once, so what the run comes to rest at reads
    // it.
    await Quiescence.settle { MintsSeen(calls: mints.withLock { $0 }, snapshot: engine.snapshot) }
    let held = engine.snapshot
    guard mints.withLock({ $0 }) > 1 || (held.error != nil && !held.isMinting) else {
      throw FixtureError(description: "the first mint never ended")
    }
    withExtendedLifetime(subscription) {}
    return mints.withLock { $0 } > 1
  }

  /// Played is what a played run stamps: each mint's call and end, on the leap's time, and the
  /// token each mint that answered one answered.
  private struct Played: Sendable {
    var calls: [Duration] = []
    var ends: [Duration] = []
    var answered: [String] = []
  }

  /// played subscribes to an engine whose mints end as `endings` lists, in order, and answers the
  /// wait from each mint's end to the next one's call, `waitsMs`.
  ///
  /// A `failure` throws the application's own error, a `timeout` the one the platform's loader
  /// raises for a call the application gave a timeout, `URLError.timedOut`, and `cancelled` the
  /// loader's report of a task the application cancelled, `URLError.cancelled`, with a reason of the
  /// application's own beside it; a `spent` token expires the instant it is answered, and a
  /// `healthy` one `lifetime` after. Every wait passes at once on the leap's time until the last
  /// mint listed is called, and from then on only up to the refresh margin past it, so a mint
  /// called again within the margin is seen and nothing past it runs.
  ///
  /// Where the last mint answers no token and an earlier one answered one, the case asks whether
  /// the source still holds it, `keepsToken`; where the last mint is cancelled, whether the mint is
  /// called again within the margin, `mintedAgain`.
  private static func played(_ endings: [String], lifetime: Duration) async throws
    -> RunnerOutcome
  {
    let answering: [String: Bool] = [
      "failure": false, "timeout": false, "cancelled": false, "spent": true, "healthy": true,
    ]
    guard !endings.isEmpty, let last = endings.last else {
      throw FixtureError(description: "the case plays no mint")
    }
    for ending in endings where answering[ending] == nil {
      throw FixtureError(description: "no mint ends with `\(ending)`")
    }
    let stamps = Locked(Played())
    let leap = Leap(horizon: .seconds(86_400 * 365))
    let engine = SessionTokenEngine(
      mint: {
        let (index, now) = stamps.withLock { stamps -> (Int, Duration) in
          let now = leap.now
          stamps.calls.append(now)
          return (stamps.calls.count - 1, now)
        }
        guard index < endings.count else {
          // A mint the case does not list is only counted: it waits for the run to be let go.
          try await HeldSeams.forGood()
          throw CancellationError()
        }
        if index == endings.count - 1 {
          leap.horizon.withLock { $0 = now + RefreshSchedule.refreshMargin }
        }
        defer { stamps.withLock { $0.ends.append(leap.now) } }
        let token = "sess_played_\(index)"
        let expiry = Duration.zero + now
        switch endings[index] {
        case "failure":
          throw MintEnding()
        case "timeout":
          throw URLError(.timedOut)
        case "cancelled":
          throw URLError(
            .cancelled,
            userInfo: [NSLocalizedFailureReasonErrorKey: "The user signed out."])
        case "spent":
          stamps.withLock { $0.answered.append(token) }
          return RestSchema.Session(
            expires_at: LeapWallClock.date(expiry), user_id: nil, token: token)
        default:
          stamps.withLock { $0.answered.append(token) }
          return RestSchema.Session(
            expires_at: LeapWallClock.date(expiry + lifetime), user_id: nil, token: token)
        }
      },
      wallClock: LeapWallClock(leap: leap),
      sleeper: leap
    )
    let subscription = engine.subscribe()
    // The last mint listed has ended once the engine's snapshot holds what it answered, its token
    // or its error with nothing minting, or once a mint it does not list is called, which carries
    // the token held into its own snapshot. One called again within the margin follows at once, so
    // a grace period after that reads it.
    let lastToken = "sess_played_\(endings.count - 1)"
    await Quiescence.settle {
      let (calls, ends) = stamps.withLock { ($0.calls.count, $0.ends.count) }
      return MintsSeen(calls: calls, ends: ends, snapshot: engine.snapshot)
    }
    let held = engine.snapshot
    let (ended, again) = stamps.withLock {
      ($0.ends.count == endings.count, $0.calls.count > endings.count)
    }
    let settled =
      ended
      && (again
        || ((answering[last] ?? false)
          ? held.token == lastToken : held.error != nil && !held.isMinting))
    guard settled else {
      throw FixtureError(
        description: "the run never reached its last mint: \(stamps.withLock { $0.calls.count }) "
          + "of \(endings.count) called")
    }
    let heldToken = engine.snapshot.token
    let run = stamps.withLock { $0 }
    withExtendedLifetime(subscription) {}

    var members = [
      OrderedJSON.Member(
        key: "waitsMs",
        value: .array(
          zip(run.calls.dropFirst().prefix(endings.count - 1), run.ends).map { call, end in
            .milliseconds(call - end)
          }))
    ]
    if !(answering[last] ?? false), let earlier = run.answered.last {
      members.append(OrderedJSON.Member(key: "keepsToken", value: .bool(heldToken == earlier)))
    }
    if last == "cancelled" {
      members.append(
        OrderedJSON.Member(key: "mintedAgain", value: .bool(run.calls.count > endings.count)))
    }
    return .value(.object(members))
  }

  /// awakeBeforeRefresh walks a wait of `delay` down in hops from a mint at the epoch, the
  /// machine going to sleep once it has been awake `sleepsAt` and waking `sleepsFor` later, and
  /// returns how long it was awake when the next hop found the deadline passed.
  ///
  /// A machine that falls asleep at the very instant a hop ends is asleep for the next hop.
  private static func awakeBeforeRefresh(
    delay: Duration,
    sleepsAt: Duration,
    sleepsFor: Duration
  ) throws(FixtureError) -> Duration {
    let mintedAt = Date(timeIntervalSince1970: 0)
    let deadline = mintedAt.addingTimeInterval(seconds(delay))
    var wall = mintedAt
    var awake = Duration.zero
    var slept = false
    var hops = 0
    while let hop = RefreshSchedule.hop(toward: deadline, now: wall) {
      hops += 1
      guard hops <= 10_000 else {
        throw FixtureError(description: "the wait was never walked down")
      }
      if !slept, awake <= sleepsAt, sleepsAt < awake + hop {
        slept = true
        wall = wall.addingTimeInterval(seconds(sleepsFor))
      }
      awake += hop
      wall = wall.addingTimeInterval(seconds(hop))
    }
    return awake
  }

  private static func milliseconds(_ duration: Duration) -> Double {
    OrderedJSON.milliseconds(duration).numberValue ?? .nan
  }

  private static func seconds(_ duration: Duration) -> TimeInterval {
    OrderedJSON.seconds(duration).numberValue ?? .nan
  }
}
