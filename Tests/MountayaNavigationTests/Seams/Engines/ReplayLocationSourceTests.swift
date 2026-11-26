import Testing

@testable import MountayaGeo
@testable import MountayaNavigation

/// The measurements a replay walking a route may cost of the route's line: one, the one the route
/// was followed with, which every tick reads its position off by a search. A measurement is a
/// haversine per vertex of the whole route, and a tick comes every interval, so a replay that
/// measured the line per tick would pay for its whole length again on every tick. Before this
/// budget, a replay measured the line once for its length, once for its start and once a tick.
private let replayMeasureBudget = 1

@Suite("ReplayLocationSource")
@MainActor
struct ReplayLocationSourceTests {
  /// eastward is 2 km east along the equator, as a route followed.
  private let eastward = [[0.0, 0], [0.018, 0]]

  private func followed(_ line: [[Double]]) throws -> FollowedRoute {
    try #require(followedRouteOf(NavigationRoute(line: line)))
  }

  /// walked starts a source, has it follow a route, and reads `count` positions it states.
  private func walked(
    _ source: ReplayLocationSource, along line: [[Double]], count: Int
  ) async throws -> [[Double]] {
    let (positions, state) = AsyncStream.makeStream(of: [Double].self)
    source.start { state.yield($0) }
    source.follow(try followed(line))
    var read: [[Double]] = []
    for await position in positions {
      read.append(position)
      if read.count == count { break }
    }
    return read
  }

  /// A device asleep in a pocket keeps a continuous clock counting, so a walk read on one would
  /// jump ahead on waking: the suspending clock stands still while the device sleeps, as
  /// `sdk-dart`'s `Stopwatch` and `sdk-kotlin`'s `TimeSource.Monotonic` do.
  @Test("the walk's own clock, where none is given, stands still while the device sleeps")
  func defaultClock() {
    #expect(ReplayLocationSource(metersPerSecond: 1).clock is SuspendingClock)
    #expect(
      ReplayLocationSource(metersPerSecond: 1, clock: ContinuousClock()).clock is ContinuousClock)
  }

  @Test("a route is walked from its start at the speed given, one position per interval")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func walksAtItsSpeed() async throws {
    let source = ReplayLocationSource(metersPerSecond: 500, clock: StepClock())
    let length = routeLengthMeters(eastward)

    let positions = try await walked(source, along: eastward, count: 3)
    source.stop()

    #expect(positions[0] == [0, 0])
    #expect(abs(haversineMeters(from: [0, 0], to: positions[1]) - 500) < 1e-6)
    #expect(abs(haversineMeters(from: [0, 0], to: positions[2]) - 1_000) < 1e-6)
    #expect(length > 1_000)
  }

  @Test("a walk ends on the route's last position, stated once")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func endsAtTheEnd() async throws {
    let source = ReplayLocationSource(
      metersPerSecond: 900, interval: .milliseconds(500), clock: StepClock())

    // 2 km at 450 m a step is five steps, the last one short, and the start before them.
    let positions = try await walked(source, along: eastward, count: 6)
    await Task.yield()
    source.stop()

    #expect(positions.last == [0.018, 0])
    #expect(Set(positions.map { $0[0] }).count == 6, "no position is stated twice")
  }

  /// A main actor too busy to wake the walk on time delays each position, never the walk: a stride
  /// added per wake would have stated 100, 200 and 300 m.
  @Test(
    "each position is placed by the time elapsed, so a late wake stands where the speed carried")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func placedByElapsedTime() async throws {
    let source = ReplayLocationSource(
      metersPerSecond: 100, interval: .seconds(1), clock: StepClock(late: .milliseconds(1_500)))

    let positions = try await walked(source, along: eastward, count: 4)
    source.stop()

    #expect(positions[0] == [0, 0])
    let meters = positions.dropFirst().map { haversineMeters(from: [0, 0], to: $0) }
    #expect(meters.count == 3)
    for (read, expected) in zip(meters, [250.0, 500, 750]) {
      #expect(abs(read - expected) < 1e-6, "\(read) m where the clock says \(expected) m")
    }
  }

  @Test("a new route is walked from its own start, and none ends the walk")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func followsEachRoute() async throws {
    let source = ReplayLocationSource(metersPerSecond: 10, clock: StepClock())
    let (positions, state) = AsyncStream.makeStream(of: [Double].self)
    var reading = positions.makeAsyncIterator()
    source.start { state.yield($0) }

    source.follow(try followed(eastward))
    #expect(await reading.next() == [0, 0])
    source.follow(try followed([[1, 1], [1.01, 1]]))
    var next = await reading.next()
    // The first walk may have stated a step before the new route was told of.
    while let position = next, position[1] == 0 { next = await reading.next() }
    #expect(next == [1, 1])

    source.follow(nil)
    source.stop()
  }

  @Test("a speed that is no number above zero, or an interval of none, stands at the start")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func standsStill() async throws {
    let still: [(speed: Double, interval: Duration)] = [
      (0, .seconds(1)), (-3, .seconds(1)), (.nan, .seconds(1)), (.infinity, .seconds(1)),
      (10, .zero), (10, .seconds(-1)),
    ]
    for (speed, interval) in still {
      let source = ReplayLocationSource(
        metersPerSecond: speed, interval: interval, clock: StepClock())
      var stated: [[Double]] = []
      source.start { stated.append($0) }
      source.follow(try followed(eastward))
      for _ in 0..<5 { await Task.yield() }
      source.stop()
      #expect(stated == [[0, 0]], "at \(speed) m/s every \(interval)")
    }
  }

  @Test("nothing is stated before a start or after a stop")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func startAndStop() async throws {
    let source = ReplayLocationSource(metersPerSecond: 10, clock: StepClock())
    var stated: [[Double]] = []
    source.follow(try followed(eastward))
    for _ in 0..<5 { await Task.yield() }
    #expect(stated.isEmpty)

    source.start { stated.append($0) }
    #expect(stated == [[0, 0]], "the walk states its start as the source starts")
    for _ in 0..<3 { await Task.yield() }
    source.stop()
    let count = stated.count
    for _ in 0..<5 { await Task.yield() }

    #expect(count > 0)
    #expect(stated.count == count)
  }

  /// A navigation reads the position it holds as a route lands: the walk's start is that position
  /// before `follow` returns, never the place a walk before it left off.
  @Test("a route followed is walked from its start, stated before follow returns")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func startStatedAtOnce() async throws {
    let source = ReplayLocationSource(metersPerSecond: 10, clock: StepClock())
    var stated: [[Double]] = []
    source.start { stated.append($0) }

    source.follow(try followed(eastward))
    #expect(stated == [[0, 0]])
    source.follow(try followed([[1, 1], [1.01, 1]]))
    #expect(stated.last == [1, 1], "a new route's start is stated as it is followed")
    source.stop()
    source.start { stated.append($0) }
    #expect(stated.last == [1, 1], "a walk started again sets out from its start")
    source.stop()
  }

  @Test("a stop the start's reading brings about ends the walk there")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func stoppedByItsStart() async throws {
    let source = ReplayLocationSource(metersPerSecond: 500, clock: StepClock())
    var stated: [[Double]] = []
    source.start { [weak source] position in
      stated.append(position)
      source?.stop()
    }
    source.follow(try followed(eastward))
    for _ in 0..<10 { await Task.yield() }

    #expect(stated == [[0, 0]])
  }

  /// zigzag is a line of `count` vertices zigzagging east from the equator, 20 m a leg.
  private func zigzag(_ count: Int) -> [[Double]] {
    (0..<count).map { index in
      [Double(index) * 0.000_15, index.isMultiple(of: 2) ? 0 : 0.000_1]
    }
  }

  @Test("hot-path budget replay-measure: sixty ticks along a long route measure its line once")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func replayMeasure() async throws {
    let line = zigzag(2_000)
    let probe = MeasureProbe()
    let source = ReplayLocationSource(metersPerSecond: 50, clock: StepClock())
    let (positions, stated) = AsyncStream.makeStream(of: [Double].self)
    var read: [[Double]] = []

    try await MeasureProbe.$current.withValue(probe) {
      source.start { stated.yield($0) }
      // The route as a navigation follows it, measured once, then sixty ticks walked along it.
      source.follow(try followed(line))
      for await position in positions {
        read.append(position)
        if read.count == 61 { break }
      }
      source.stop()
    }

    // The work happened: the start and sixty ticks, each 50 m further along the line, the last
    // where the line's own reading places 3 km.
    #expect(read.count == 61)
    #expect(read.first == line[0])
    let along = read.map { position in
      cumulativeMeters([line[0], position]).last ?? 0
    }
    #expect(zip(along, along.dropFirst()).allSatisfy { $0 < $1 }, "\(along)")
    #expect(read.last == positionAtMeters(line, meters: 3_000))
    // The line measured once, as the route was followed, and nothing else measured.
    let measured = probe.lines.filter { $0 == line }.count
    #expect((1...replayMeasureBudget).contains(measured), "measured \(measured)")
    #expect(probe.lines.count == measured, "\(probe.lines.count) measurements")
  }

  @Test("each position a walk states is the one the line's own reading places, to the last digit")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func positionsAsTheLineReads() async throws {
    // A vertex short of a latitude, one at no number, and a leg across the antimeridian.
    let line: [[Double]] = [
      [179.99, 0.01], [179.995, 0.02], [.nan, 0], [-179.998, 0.03], [-179.99], [-179.985, 0.02],
    ]
    let source = ReplayLocationSource(metersPerSecond: 97.3, clock: StepClock())
    let positions = try await walked(source, along: line, count: 30)
    source.stop()

    let length = routeLengthMeters(line)
    for (tick, position) in positions.enumerated() {
      let expected = positionAtMeters(line, meters: Swift.min(length, 97.3 * Double(tick)))
      #expect(position == expected, "tick \(tick)")
    }
  }

  @Test("a position the navigation refuses ends the walk")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func refusalEndsTheWalk() async throws {
    let source = ReplayLocationSource(metersPerSecond: 10, clock: StepClock())
    var tries = 0
    struct Refused: Error {}
    source.start { _ in
      tries += 1
      throw Refused()
    }
    source.follow(try followed(eastward))
    for _ in 0..<10 { await Task.yield() }
    source.stop()

    #expect(tries == 1)
  }
}
