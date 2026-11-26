import Observation

/// GeolocateControlEngine is the state of a control that centres a map on the device
/// (`geo.controls.geolocate-state`): whether a fix is out, whether location stands refused, and
/// whether a press has a map to ask.
///
/// - **Busy from a press until its fix settles.** Each press asks the map for one fix, and the
///   control is busy while any fix it asked for is out, a map replaced meanwhile included.
/// - **Live after a refusal.** A refusal changes nothing a press needs, so the control stays
///   pressable: a disabled control offers no way back, where a live one can say where the setting
///   is and be pressed again once it changed.
/// - **Blocked only on the permission's word.** The standing permission is read through the map,
///   which prompts nobody, when the control comes to stand over a map and again once each fix
///   asked of that map settles while it still stands over it, and the control says location is
///   blocked while the latest read answers refused. A fix that timed out or found no signal fails
///   with location still allowed, and is no refusal of the permission; a fix refused while the
///   permission was never asked, which nothing prompts for, leaves it never asked. A read that
///   throws says nothing is refused, one that never answers leaves what was said as it stood, an
///   answer from an earlier read or from a map the control no longer stands over lands nowhere,
///   and a control standing over another map, or none, says nothing is blocked until its
///   permission is read.
///
/// ```swift
/// let control = GeolocateControlEngine(map: map)
/// control.locate(onError: { error in shown = error })
/// ```
///
/// It reads the permission as soon as it is handed a map, by its initializer as by
/// `configure(map:)`, since Observation tells an engine nothing of its readers, and keeps no time.
/// It is bound to the main actor, as every engine is, and `Observable`, so a SwiftUI view that
/// reads `state` is drawn again when it changes. It reports a state only where it differs from the
/// one it holds, and a closed engine is inert.
@MainActor
@Observable
public final class GeolocateControlEngine {
  /// state is what the control shows.
  public var state: GeolocateControlState { held }

  /// held is the state the engine holds, which an observer of `state` is told of.
  private var held: GeolocateControlState

  /// map is the map the control stands over, or nil for none.
  @ObservationIgnored private var map: (any GeolocateControlTarget)?
  /// fixesOut counts the fixes the control asked for that are still out.
  @ObservationIgnored private var fixesOut = 0
  /// latestRead is the number of the latest permission read, the one alone whose answer lands.
  @ObservationIgnored private var latestRead = 0
  @ObservationIgnored private var closed = false
  /// subscribers is every stream `subscribe()` returned that has not ended, by its number.
  @ObservationIgnored private var subscribers:
    [Int: AsyncStream<GeolocateControlState>.Continuation] = [:]
  @ObservationIgnored private var nextSubscriber = 0

  /// Creates the state of a control standing over `map`, whose permission it reads at once, or
  /// over none.
  public init(map: (any GeolocateControlTarget)? = nil) {
    self.map = map
    held = GeolocateControlState(isLive: map != nil)
    readPermission()
  }

  deinit {
    // An engine let go of ends its streams, so no reader waits on a state that never comes.
    for continuation in subscribers.values {
      continuation.finish()
    }
  }

  /// subscribe returns a stream that yields the state as it is now, then every state that differs
  /// from the one before it, in order, for as long as the stream is held. It ends at `close()`.
  public func subscribe() -> AsyncStream<GeolocateControlState> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: GeolocateControlState.self, bufferingPolicy: .unbounded)
    continuation.yield(held)
    if closed {
      continuation.finish()
      return stream
    }
    let number = nextSubscriber
    nextSubscriber += 1
    subscribers[number] = continuation
    return stream
  }

  /// configure stands the control over `map`. The map it stands over already changes nothing;
  /// another one, nil included, drops every read still out, says nothing is blocked, and reads the
  /// new map's permission. A fix still out stays the control's own.
  public func configure(map: (any GeolocateControlTarget)?) {
    guard !closed, map !== self.map else { return }
    self.map = map
    latestRead += 1
    var next = held
    next.isBlocked = false
    next.isLive = map != nil
    commit(next)
    readPermission()
  }

  /// locate asks the map the control stands over for one fix, and does nothing with no map. Once
  /// the fix settles the permission is read again through that map, while the control still stands
  /// over it, and a fix that failed is handed to `onError` with what the map threw, unless the
  /// engine was closed by then.
  public func locate(onError: (@MainActor (any Error) -> Void)? = nil) {
    guard !closed, let map else { return }
    fixesOut += 1
    var busy = held
    busy.isBusy = true
    commit(busy)
    Task { [weak self] in
      var failure: (any Error)?
      do {
        _ = try await map.locate()
      } catch {
        failure = error
      }
      guard let self, !self.closed else { return }
      self.fixesOut -= 1
      var next = self.held
      next.isBusy = self.fixesOut > 0
      self.commit(next)
      // A fix that settled may have changed the standing answer: a prompt the reader refused now
      // stands refused, and a setting they changed back stands allowed.
      if map === self.map {
        self.readPermission()
      }
      if let failure {
        onError?(failure)
      }
    }
  }

  /// close stops the engine for good: no answer lands after it, no failure is handed on, every
  /// stream ends, and every later command does nothing. The state stays as it was.
  public func close() {
    guard !closed else { return }
    closed = true
    latestRead += 1
    map = nil
    let ended = subscribers.values
    subscribers = [:]
    for continuation in ended {
      continuation.finish()
    }
  }

  /// readPermission reads the standing permission of the map the control stands over, and writes
  /// its answer while the read is still the latest.
  private func readPermission() {
    guard !closed, let map else { return }
    latestRead += 1
    let read = latestRead
    Task { [weak self] in
      let isRefused: Bool
      do {
        isRefused = try await map.isLocationRefused()
      } catch {
        isRefused = false
      }
      guard let self, !self.closed, self.latestRead == read else { return }
      var next = self.held
      next.isBlocked = isRefused
      self.commit(next)
    }
  }

  /// commit holds `next` and tells every stream of it, where it differs from the state held.
  private func commit(_ next: GeolocateControlState) {
    guard next != held else { return }
    held = next
    for continuation in subscribers.values {
      continuation.yield(next)
    }
  }
}
