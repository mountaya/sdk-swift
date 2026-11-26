import MountayaGeo

@testable import MountayaNavigation

/// RecordingVoice keeps every instruction a navigation hands it, and how often it was hushed.
@MainActor
final class RecordingVoice: NavigationVoice {
  var said: [NavigationInstruction] = []
  var hushed = 0

  func say(_ instruction: NavigationInstruction) {
    said.append(instruction)
  }

  func hush() {
    hushed += 1
  }
}

/// RecordingLocationSource keeps what a navigation asks of it, and states a position when the test
/// says, as the platform would.
@MainActor
final class RecordingLocationSource: LocationSource {
  var started = 0
  var stopped = 0
  var followed: [FollowedRoute?] = []
  private var deliver: (@MainActor ([Double]) throws -> Void)?

  func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {
    started += 1
    self.deliver = deliver
  }

  func stop() {
    stopped += 1
    deliver = nil
  }

  func follow(_ route: FollowedRoute?) {
    followed.append(route)
  }

  /// state hands a position to the navigation, as a fix the platform reports, and answers false
  /// where the source is not started.
  @discardableResult
  func state(_ position: [Double]) throws -> Bool {
    guard let deliver else { return false }
    try deliver(position)
    return true
  }
}

/// EagerLocationSource states a position the moment it is told of a route, as an app's own source
/// that reads where the traveller stands at once may.
@MainActor
final class EagerLocationSource: LocationSource {
  private let position: [Double]
  private var deliver: (@MainActor ([Double]) throws -> Void)?

  init(at position: [Double]) {
    self.position = position
  }

  func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {
    self.deliver = deliver
  }

  func stop() {
    deliver = nil
  }

  func follow(_ route: FollowedRoute?) {
    guard route != nil else { return }
    try? deliver?(position)
  }
}

/// settled reads a stream of states until one of `status` comes, and answers it, or nil where the
/// stream ends first.
func settled(_ states: AsyncStream<NavigationState>, at status: NavigationStatus) async
  -> NavigationState?
{
  for await state in states where state.status == status {
    return state
  }
  return nil
}

/// recorded reads every state a stream yields until it ends.
func recorded(_ states: AsyncStream<NavigationState>) async -> [NavigationState] {
  var seen: [NavigationState] = []
  for await state in states {
    seen.append(state)
  }
  return seen
}

/// walk is every position `every` meters apart along a line, from its start to its end, as Geo
/// places a position along a line (`positionAtMeters(_:meters:)`): a traveller's fixes, one after
/// another, as a device moving along the line reports them.
func walk(_ line: [[Double]], every meters: Double = 5) -> [[Double]] {
  let length = routeLengthMeters(line)
  var positions = stride(from: 0, to: length, by: meters).map {
    positionAtMeters(line, meters: $0)
  }
  positions.append(positionAtMeters(line, meters: length))
  return positions
}
