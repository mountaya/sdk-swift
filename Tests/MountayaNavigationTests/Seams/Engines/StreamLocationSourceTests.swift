import MountayaGeo
import Testing

@testable import MountayaNavigation

@Suite("StreamLocationSource")
@MainActor
struct StreamLocationSourceTests {
  private struct Lost: Error {}

  /// Fixes is a sequence of the app's own that makes a stream of its own each time it is
  /// iterated, as an app hands a source it starts more than once, and counts the iterations.
  private struct Fixes: AsyncSequence, Sendable {
    let made: AsyncStream<AsyncStream<[Double]>.Continuation>.Continuation

    func makeAsyncIterator() -> AsyncStream<[Double]>.Iterator {
      let (positions, continuation) = AsyncStream.makeStream(of: [Double].self)
      made.yield(continuation)
      return positions.makeAsyncIterator()
    }
  }

  /// waited waits until `stated` holds `count` positions, the main actor turning meanwhile, for a
  /// thousand turns at most, and answers what it holds then.
  private func waited(for count: Int, in stated: () -> [[Double]]) async -> [[Double]] {
    for _ in 0..<1_000 where stated().count < count {
      await Task.yield()
    }
    return stated()
  }

  @Test("each position the sequence yields from a start to a stop is stated, and none after")
  func statesFromStartToStop() async throws {
    let (positions, fix) = AsyncStream.makeStream(of: [Double].self)
    let source = StreamLocationSource(positions)
    var stated: [[Double]] = []

    source.start { stated.append($0) }
    fix.yield([1, 1])
    fix.yield([2, 2])
    #expect(await waited(for: 2) { stated } == [[1, 1], [2, 2]])

    source.stop()
    fix.yield([3, 3])
    for _ in 0..<10 { await Task.yield() }
    #expect(stated == [[1, 1], [2, 2]], "a stop ends the positions")
  }

  @Test("a source started twice reads once, and reads its sequence afresh after a stop")
  func startedOnce() async throws {
    let (iterations, made) = AsyncStream.makeStream(of: AsyncStream<[Double]>.Continuation.self)
    var iterated = iterations.makeAsyncIterator()
    let source = StreamLocationSource(Fixes(made: made))
    var stated: [[Double]] = []

    source.start { stated.append($0) }
    source.start { stated.append($0) }
    let first = try #require(await iterated.next())
    first.yield([1, 1])
    #expect(await waited(for: 1) { stated } == [[1, 1]])

    source.stop()
    source.stop()
    source.start { stated.append($0) }
    let second = try #require(await iterated.next())
    second.yield([4, 4])
    #expect(await waited(for: 2) { stated } == [[1, 1], [4, 4]])
    first.yield([9, 9])
    for _ in 0..<10 { await Task.yield() }
    #expect(stated == [[1, 1], [4, 4]], "the first iteration ended with its stop")
    source.stop()
  }

  @Test("a position the engine refuses is told to onError, and the next is stated")
  func refusalToldAndReadOn() async throws {
    let (positions, fix) = AsyncStream.makeStream(of: [Double].self)
    var told: [any Error] = []
    let source = StreamLocationSource(positions) { told.append($0) }
    let engine = RouteFollowingEngine<String> { _ in
      NavigationRoute(line: [[0, 0], [0.01, 0]])
    }
    var read: [[Double]] = []
    source.start { position in
      try engine.setPosition(position)
      read.append(position)
    }

    fix.yield([.nan, 0])
    fix.yield([0.005, 0])
    #expect(await waited(for: 1) { read } == [[0.005, 0]])
    #expect(told.count == 1)
    #expect(told.first is PositionError)
    source.stop()
    engine.close()
  }

  @Test("an error the sequence throws ends the positions and is told, a stop's cancellation not")
  func sequenceError() async throws {
    let (positions, fix) = AsyncThrowingStream.makeStream(of: [Double].self)
    var told: [any Error] = []
    let source = StreamLocationSource(positions) { told.append($0) }
    var stated: [[Double]] = []

    source.start { stated.append($0) }
    fix.yield([1, 1])
    fix.finish(throwing: Lost())
    #expect(await waited(for: 1) { stated } == [[1, 1]])
    for _ in 0..<1_000 where told.isEmpty { await Task.yield() }
    #expect(told.count == 1)
    #expect(told.first is Lost)

    let (more, _) = AsyncStream.makeStream(of: [Double].self)
    let quiet = StreamLocationSource(more) { told.append($0) }
    quiet.start { _ in }
    for _ in 0..<5 { await Task.yield() }
    quiet.stop()
    for _ in 0..<10 { await Task.yield() }
    #expect(told.count == 1, "a stop is no failure")
  }

  @Test("it is the source a navigation reads the app's own positions through")
  func feedsAnEngine() async throws {
    let (positions, fix) = AsyncStream.makeStream(of: [Double].self)
    let location = StreamLocationSource(positions)
    let route = NavigationRoute(line: [[0, 0], [0.01, 0]])
    let navigation = DeviceNavigationEngine<String>(
      route: { _ in route }, location: location, voice: RecordingVoice())

    navigation.start("summit")
    _ = await settled(navigation.subscribe(), at: .navigating)
    fix.yield([0.005, 0])
    for _ in 0..<1_000 where navigation.state.progress == nil { await Task.yield() }
    #expect(navigation.state.progress?.along ?? 0 > 0)
    navigation.close()
  }
}
