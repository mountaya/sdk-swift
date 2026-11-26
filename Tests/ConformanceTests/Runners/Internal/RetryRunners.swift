import Foundation
import GateSupport
import Simulation

@testable import MountayaClient

extension InternalRunners {
  /// errorsRetryAfter answers with the wait a header asks for, in the whole seconds an error
  /// carries, against the case's own instant: an HTTP date's distance rounded up, so a caller that
  /// waits it out never comes back early.
  static let errorsRetryAfter = Runner(id: "transport.errors.retry-after", table: .internal) {
    _, fixtureCase in
    let now = Date(timeIntervalSince1970: try fixtureCase.input.number(at: "nowMs") / 1000)
    let carried = AnswerError.retryAfter(
      in: [AnswerError.retryAfterHeader: try fixtureCase.input.string(at: "header")], now: now)
    return .value(carried.map(OrderedJSON.seconds) ?? .null)
  }

  /// retryEligibility answers whether the attempt is followed by another: whether its answer is
  /// one the contract repeats, and then whether the wait that answer names fits the call's
  /// budget.
  ///
  /// The fixture's policy waits no time of its own, so the only wait is the one `Retry-After`
  /// names, and its draw is taken at zero, the wait the answer names; no case sits where the draw
  /// would decide. The fixture names no wait before the attempt, so none is counted.
  static let retryEligibility = Runner(id: "transport.retry.eligibility", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    let policy = try RetryPolicy(
      maxRetries: try input.integer(at: "maxRetries"),
      baseDelay: .zero,
      maxDelay: .zero
    )
    let attempt = try input.integer(at: "attempt")
    let repeated = RetryEligibility.allowsRetry(
      after: attempt,
      status: try input.optionalInteger(at: "status"),
      code: try input.optionalString(at: "code").map(APIErrorCode.init(rawValue:)),
      idempotent: try input.flag(at: "idempotent"),
      keyed: try input.flag(at: "keyed"),
      policy: policy
    )
    let retryAfter = try input.optionalString(at: "retryAfterHeader").flatMap {
      RetryAfter.delay(header: $0, now: Date(timeIntervalSince1970: 0))
    }
    let fits =
      Backoff.delay(
        after: attempt,
        policy: policy,
        draw: 0,
        retryAfter: retryAfter,
        waited: .zero
      ) != nil
    return .value(.bool(repeated && fits))
  }

  /// retryBackoff answers with the wait before the next attempt, in milliseconds, for the
  /// case's draw, or null where that wait does not fit the call's budget, after holding the
  /// standard policy and the jitter to the fixture's.
  ///
  /// Every attempt before the case's is answered with a 429 naming no wait, so each waited its
  /// schedule with the same draw; those waits are taken through the same rule and counted
  /// against the budget before the case's own.
  ///
  /// A case naming `retryAfter`, an HTTP date, is played through the client's own retry loop
  /// instead (`retryAfterDate`).
  static let retryBackoff = Runner(id: "transport.retry.backoff", table: .internal) {
    fixture, fixtureCase in
    let defaults = fixture.defaults ?? .object([])
    let constants = fixture.constants ?? .object([])
    let standard = RetryPolicy.standard
    guard try defaults.integer(at: "maxRetries") == standard.maxRetries,
      try OrderedJSON.number(defaults.number(at: "baseDelayMs"))
        == OrderedJSON.milliseconds(standard.baseDelay),
      try OrderedJSON.number(defaults.number(at: "maxDelayMs"))
        == OrderedJSON.milliseconds(standard.maxDelay),
      try OrderedJSON.number(defaults.number(at: "maxWaitMs"))
        == OrderedJSON.milliseconds(standard.waitBudget),
      try OrderedJSON.number(constants.number(at: "retryAfterJitterMs"))
        == OrderedJSON.milliseconds(Backoff.retryAfterJitter)
    else {
      throw FixtureError(description: "the fixture's defaults are not the standard policy")
    }

    let input = fixtureCase.input
    let waitBudget = try input.optionalNumber(at: "maxWaitMs").map { Duration.milliseconds($0) }
    let policy = try RetryPolicy(
      baseDelay: .milliseconds(try input.number(at: "baseDelayMs")),
      maxDelay: .milliseconds(try input.number(at: "maxDelayMs")),
      waitBudget: waitBudget ?? standard.waitBudget
    )
    let attempt = try input.integer(at: "attempt")
    let draw = try input.number(at: "random")
    if let date = try input.optionalString(at: "retryAfter") {
      guard attempt == 0 else {
        throw FixtureError(description: "a date is played on the call's first attempt alone")
      }
      let answeredAt = Date(timeIntervalSince1970: try input.number(at: "answeredAtMs") / 1000)
      let delay = try await retryAfterDate(
        date, answeredAt: answeredAt, policy: policy, draw: draw)
      return .value(delay.map(OrderedJSON.milliseconds) ?? .null)
    }
    var waited = Duration.zero
    for earlier in 0..<attempt {
      guard
        let wait = Backoff.delay(
          after: earlier, policy: policy, draw: draw, retryAfter: nil, waited: waited)
      else {
        throw FixtureError(description: "an attempt before the case's was not repeated")
      }
      waited += wait
    }
    let delay = Backoff.delay(
      after: attempt,
      policy: policy,
      draw: draw,
      retryAfter: try input.optionalNumber(at: "retryAfterSeconds").map { .seconds($0) },
      waited: waited
    )
    return .value(delay.map(OrderedJSON.milliseconds) ?? .null)
  }

  /// retryAfterDate calls an idempotent read whose first attempt is answered a 429 naming `date`
  /// at `answeredAt`, on a client whose wall clock reads that instant and whose every draw is
  /// `draw`, and returns how long its loop waited before the next attempt, on a simulation's clock,
  /// or nil where it sent none, the 429 then the call's error.
  private static func retryAfterDate(
    _ date: String,
    answeredAt: Date,
    policy: RetryPolicy,
    draw: Double
  ) async throws -> Duration? {
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await Simulation.run { simulation -> Duration? in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [
          .answer(
            status: 429, headers: ["Retry-After": date],
            body: Scripted.errorBody(code: "TOO_MANY_REQUESTS")),
          .answer(status: 200, body: Scripted.emptySuccess),
        ])
      let client = try Mountaya(
        credential: .publishable(key: "pk_test_abc"),
        retry: policy,
        exchange: exchange,
        clock: simulation.clock,
        random: Scripted.Random(draw: draw),
        wallClock: PublicRunners.FixedWallClock(now: answeredAt)
      )
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          PublicRunners.aRead, path: "/v1/things")
      } catch MountayaError.api(let error) where error.status == 429 {
        guard await exchange.sent.count == 1 else {
          throw FixtureError(description: "the call failed after a second attempt")
        }
        return nil
      }
      let sent = await exchange.sent
      let ended = await exchange.ended
      guard sent.count == 2, let answered = ended.first else {
        throw FixtureError(description: "\(sent.count) attempts, expected the 429's and one more")
      }
      return sent[1].at - answered.at
    }
  }

  /// retryInterruptible waits through the client's own sleeper on a simulation's clock, reading the
  /// fixture's `abort` as the cancellation of the task that waits (SPEC.md section 9): `before` is a
  /// child task cancelled before its wait, `during` a cancellation 50 simulated milliseconds into
  /// the wait, `never` a child task nothing cancels and `none` a wait in the runner's own task, and
  /// the caller's own cancellation is `CancellationError`. Whether it settled before the wait's
  /// time passed is read off the simulation's clock, so no run depends on the machine's.
  static let retryInterruptible = Runner(
    id: "transport.retry.interruptible",
    table: .internal
  ) { _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let delay = Duration.milliseconds(try fixtureCase.input.integer(at: "delayMs"))
    let abort = try fixtureCase.input.string(at: "abort")
    guard ["none", "never", "before", "during"].contains(abort) else {
      throw FixtureError(description: "no abort is called `\(abort)`")
    }
    let (result, elapsed) = try await Simulation.run {
      simulation -> (Result<Void, any Error>, Duration) in
      let sleeper = ClockSleeper(clock: simulation.clock)
      /// waited is how a wait of `delay` settled.
      @Sendable func waited() async -> Result<Void, any Error> {
        do {
          try await sleeper.sleep(for: delay)
          return .success(())
        } catch {
          return .failure(error)
        }
      }
      if abort == "none" {
        return (await waited(), simulation.elapsed)
      }
      // A child task keeps to the simulation's executor, where a task of its own would leave it.
      let settled = await withTaskGroup(of: Result<Void, any Error>.self) { group in
        group.addTask { await waited() }
        switch abort {
        case "before":
          group.cancelAll()
        case "during":
          try? await simulation.clock.sleep(for: .milliseconds(50))
          group.cancelAll()
        default:
          break
        }
        return await group.next() ?? .success(())
      }
      return (settled, simulation.elapsed)
    }

    let reason: (any Error)?
    if case .failure(let error) = result {
      reason = error
    } else {
      reason = nil
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "outcome",
          value: .string(reason == nil ? "resolved" : "rejected")
        ),
        OrderedJSON.Member(key: "reasonIsAbortReason", value: .bool(reason is CancellationError)),
        OrderedJSON.Member(key: "settledBeforeDelayElapsed", value: .bool(elapsed < delay)),
      ])
    )
  }
}
