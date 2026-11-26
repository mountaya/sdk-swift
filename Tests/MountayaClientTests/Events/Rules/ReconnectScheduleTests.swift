import Testing

@testable import MountayaClient

@Suite("ReconnectSchedule")
struct ReconnectScheduleTests {
  private static let dropped = MountayaError.connection(ConnectionError())

  private static func answered(_ status: Int, retryAfter: Duration? = nil) -> MountayaError {
    .api(APIError(status: status, retryAfter: retryAfter))
  }

  /// opens counts every failure in turn, each ended at its instant, and returns the wait after
  /// each, nil where the reader stopped, with the count after the last.
  private static func opens(
    _ failures: [(failure: MountayaError?, at: Duration)],
    rules: EventStreamRules,
    draw: Double = 1
  ) -> (waits: [Duration?], count: ReconnectSchedule.Count) {
    var count = ReconnectSchedule.Count()
    var waits: [Duration?] = []
    for (failure, at) in failures {
      let next = ReconnectSchedule.next(
        after: failure, count: count, at: at, rules: rules, draw: draw)
      count = next.count
      waits.append(next.wait)
    }
    return (waits, count)
  }

  @Test("the ceiling doubles per open without progress up to its cap, and the draw scales it")
  func ceiling() {
    let waits = (1...6).map {
      ReconnectSchedule.drawnWait(afterOpensWithoutProgress: $0, rules: .agentRun, draw: 1)
    }

    #expect(
      waits == [
        .milliseconds(500), .seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(8),
      ])
    #expect(
      ReconnectSchedule.drawnWait(afterOpensWithoutProgress: 3, rules: .agentRun, draw: 0.5)
        == .seconds(1))
    #expect(
      ReconnectSchedule.drawnWait(
        afterOpensWithoutProgress: 7, rules: .collaborationFeed, draw: 1)
        == .seconds(15))
  }

  @Test("an agent run's reader stops past six reopens without progress, a feed's never")
  func stops() {
    let drops = Array(repeating: (failure: Optional(Self.dropped), at: Duration.zero), count: 7)

    #expect(Self.opens(drops, rules: .agentRun).waits.last == .some(nil))
    #expect(Self.opens(Array(drops.prefix(6)), rules: .agentRun).waits.allSatisfy { $0 != nil })
    #expect(
      Self.opens(Array(repeating: (nil, .zero), count: 1000), rules: .collaborationFeed).waits
        .allSatisfy { $0 != nil })
    #expect(
      Self.opens(Array(repeating: (nil, .zero), count: 1000), rules: .collaborationEditor).waits
        .allSatisfy { $0 != nil })
  }

  @Test("a 429 or a 503 naming its wait is waited out with up to a second's draw above it")
  func namedWaits() {
    for rules in [EventStreamRules.agentRun, .collaborationFeed, .collaborationEditor] {
      for status in [429, 503] {
        let named = ReconnectSchedule.next(
          after: Self.answered(status, retryAfter: .seconds(1)),
          count: ReconnectSchedule.Count(),
          at: .zero,
          rules: rules,
          draw: 0.5
        )
        let thirty = ReconnectSchedule.next(
          after: Self.answered(status, retryAfter: .seconds(30)),
          count: ReconnectSchedule.Count(),
          at: .zero,
          rules: rules,
          draw: 1
        )
        #expect(named.wait == .milliseconds(1500))
        #expect(thirty.wait == .seconds(31))
      }
    }
  }

  @Test("a wait of 0 seconds named in Retry-After is the draw alone, never the schedule")
  func namedWaitOfZero() {
    for rules in [EventStreamRules.agentRun, .collaborationFeed, .collaborationEditor] {
      // The schedule's wait would be a quarter of the ceiling's 8 seconds after 5 opens.
      let count = Self.opens(Array(repeating: (Self.dropped, .zero), count: 4), rules: rules).count
      let zero = ReconnectSchedule.next(
        after: Self.answered(429, retryAfter: .zero), count: count, at: .zero, rules: rules,
        draw: 0.25)
      #expect(zero.wait == .milliseconds(250))
    }
  }

  @Test("a named wait still doubles the ceiling, and a 503 naming none waits on the schedule")
  func namedWaitsDoubleTheCeiling() {
    let named = Self.opens(
      [(Self.answered(429, retryAfter: .seconds(1)), .zero), (Self.dropped, .seconds(2))],
      rules: .agentRun, draw: 0.5)
    let unnamed = Self.opens(
      Array(repeating: (Self.answered(503), .zero), count: 8), rules: .agentRun)

    #expect(named.waits == [.milliseconds(1500), .milliseconds(500)])
    #expect(
      unnamed.waits == [
        .milliseconds(500), .seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(8),
        .seconds(8), .seconds(8),
      ])
  }

  @Test("only a 429's and a 503's Retry-After name a wait")
  func onlyTheirWaitsAreNamed() {
    #expect(ReconnectSchedule.namedWait(Self.answered(429, retryAfter: .zero)) == .zero)
    #expect(ReconnectSchedule.namedWait(Self.answered(503, retryAfter: .seconds(1))) == .seconds(1))
    #expect(ReconnectSchedule.namedWait(Self.answered(504, retryAfter: .seconds(1))) == nil)
    #expect(ReconnectSchedule.namedWait(Self.answered(503)) == nil)
    #expect(ReconnectSchedule.namedWait(Self.dropped) == nil)
    #expect(ReconnectSchedule.namedWait(nil) == nil)
  }

  @Test("an agent run's opens answered 429 are counted among the six")
  func rateLimitedOpensCount() {
    let opens = Self.opens(
      Array(repeating: (Self.answered(429, retryAfter: .seconds(1)), .zero), count: 7),
      rules: .agentRun)

    #expect(opens.waits.prefix(6).allSatisfy { $0 == .seconds(2) })
    #expect(opens.waits.last == .some(nil))
  }

  @Test("an agent run's opens answered 503 neither add to the six nor clear them")
  func unavailableOpensAreNotCounted() {
    let fiveDrops = Array(repeating: (failure: Optional(Self.dropped), at: Duration.zero), count: 5)
    let unavailable = (
      failure: Optional(Self.answered(503, retryAfter: .seconds(1))), at: Duration.zero
    )
    let opens = Self.opens(
      fiveDrops + Array(repeating: unavailable, count: 20) + [(Self.dropped, .zero)]
        + [(Self.dropped, .zero)],
      rules: .agentRun)

    #expect(opens.waits.dropLast().allSatisfy { $0 != nil })
    #expect(opens.waits.last == .some(nil))
    #expect(opens.count.opens == 27)
    #expect(opens.count.unavailableOpens == 20)
  }

  @Test("an agent run's open answered 503 two minutes or more after the first stops the reader")
  func unavailableOpensAreHeldToTwoMinutes() {
    let unavailable = Self.answered(503, retryAfter: .seconds(30))
    let within = Self.opens(
      [(unavailable, .seconds(10)), (unavailable, .seconds(129) + .milliseconds(999))],
      rules: .agentRun)
    let past = Self.opens(
      [(unavailable, .seconds(10)), (unavailable, .seconds(130))], rules: .agentRun)

    #expect(within.waits == [.seconds(31), .seconds(31)])
    #expect(within.count.firstUnavailable == .seconds(10))
    #expect(past.waits == [.seconds(31), nil])
  }

  @Test("a failure between two opens answered 503 neither restarts the two minutes nor stops them")
  func otherFailuresDoNotRestartTheTwoMinutes() {
    let unavailable = Self.answered(503, retryAfter: .seconds(30))
    let opens = Self.opens(
      [
        (unavailable, .zero), (Self.dropped, .seconds(31)), (Self.dropped, .seconds(200)),
        (unavailable, .seconds(201)),
      ],
      rules: .agentRun)

    #expect(opens.waits == [.seconds(31), .seconds(1), .seconds(2), nil])
  }

  @Test("a collaboration feed's opens answered 503 never stop its reader")
  func collaborationUnavailableOpensNeverStop() {
    for rules in [EventStreamRules.collaborationFeed, .collaborationEditor] {
      let unavailable = Self.answered(503, retryAfter: .seconds(30))
      let opens = Self.opens(
        (0..<10).map { (unavailable, .seconds(31 * Int64($0))) }, rules: rules)

      #expect(opens.waits.allSatisfy { $0 == .seconds(31) })
    }
  }
}
