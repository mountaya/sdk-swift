import MountayaGeo
import Observation

/// DeviceNavigationEngine is the `NavigationEngine` an app navigates with: Geo's machine,
/// `RouteFollowingEngine`, with the device's positions beside it, and guidance that says each
/// maneuver aloud before the traveller reaches it.
///
/// Every number and every word it reports is Geo's, so it answers exactly as
/// `ScriptedNavigationEngine` answers in an app's tests and as the other SDKs' engines answer: the
/// status, the progress, the arrival and the route requests are the machine's, and a traveller is
/// off the route past 50 m (`isOffRouteAt(_:lines:)`). It differs from the machine only in where a
/// position comes from and in what it says.
///
/// Its seams are given at construction:
///
/// - `route`, the host's call for a route, one line over its own client, answering the
///   `NavigationRoute` to follow (`NavigationRouteSource`).
/// - `location`, where positions come from: `DeviceLocationSource` for the device's own,
///   `ReplayLocationSource` to walk each route followed, `StreamLocationSource` over the app's
///   own sequence of positions, the app's own `LocationSource`, or the default
///   `InertLocationSource`, where the app hands each position to `setPosition(_:)`. It runs from
///   the first `start(_:)` to `stop()` or `close()`, each position it states read as
///   `setPosition(_:)` reads one, a refused one thrown back to it, and it is told of each route
///   followed, `LocationSource.follow(_:)`, once the engine follows it.
/// - `voice`, which says each maneuver: `SpeechNavigationVoice` in the host's words, the app's
///   own `NavigationVoice`, or the default `InertNavigationVoice`, which says nothing.
///
/// The guidance lays each route followed out, `guidancePlanOf(_:)`: each maneuver is announced from
/// the step that leads to it, 50 m before that step's end or as the step begins where it is
/// shorter, the departure as the first step begins, and nothing from the last step; a step of no
/// length announces from the step of length before it, as that step ends, or, opening the route,
/// from the first step of length, as it begins, its departure dropped. At each state
/// the machine commits, the prompt due is read on the step Geo's progress names, from the distance
/// left to its end (`duePrompt(_:progress:)`), and said once per route, only while the navigation
/// is `navigating`. A route that lands while a position is held says nothing until that position
/// is read on it, and a new route, a stop and a close hush the voice.
///
/// It reads no clock: a position is judged by where it is. It never asks for location access, and
/// reads with the screen off only where the app asks its location source to: both are the app's.
/// It closes no seam it is handed: the app that made a source or a voice ends it. It names no
/// platform framework, so it follows a route on every platform the package builds on; the seams
/// that read the device are the platform's own.
///
/// ```swift
/// let navigation = DeviceNavigationEngine<[[Double]]>(
///   route: { waypoints in try await routeFromYourClient(waypoints) },
///   location: ReplayLocationSource(metersPerSecond: 1.4)
/// )
/// navigation.start([[6.8652, 45.9237], [6.9271, 45.9682]])
/// ```
///
/// It is bound to the main actor, as every engine is, and `Observable`, so a SwiftUI view that
/// reads `state` is drawn again when it changes. The machine tells it each state through
/// `onChange`, inline and before any stream is handed it, so no reader sees a route land that the
/// guidance does not follow yet. `Request` is what the app asks a route for.
@MainActor
@Observable
public final class DeviceNavigationEngine<Request: Sendable>: NavigationEngine {
  @ObservationIgnored private let following: RouteFollowingEngine<Request>
  @ObservationIgnored private let location: any LocationSource
  @ObservationIgnored private let voice: any NavigationVoice
  /// route is the route guided, the one the machine followed when it last told a state.
  @ObservationIgnored private var route: FollowedRoute?
  /// plan is the guidance's layout of `route`, nil where it follows none or one with no vertex
  /// that names a place.
  @ObservationIgnored private var plan: GuidancePlan?
  /// said is every prompt of the route guided that was said, by its id.
  @ObservationIgnored private var said: Set<Int> = []
  /// holdsPosition is whether the machine holds a position, which it reads against each route
  /// that lands.
  @ObservationIgnored private var holdsPosition = false
  /// locating is whether the location source runs, from the first start to a stop.
  @ObservationIgnored private var locating = false
  /// halting is true while a stop hands the machine its command, whose state `halt()` keeps to.
  @ObservationIgnored private var halting = false
  @ObservationIgnored private var closed = false

  /// Creates an engine that is idle, asks `route` for each route it follows, reads positions
  /// from `location` and says each maneuver through `voice`.
  public init(
    route: @escaping NavigationRouteSource<Request>,
    location: any LocationSource = InertLocationSource(),
    voice: any NavigationVoice = InertNavigationVoice()
  ) {
    // A route that lands is the machine's own doing, in a turn of its own, so the guidance follows
    // the machine's states as it commits them, inline, before any stream is handed one.
    weak var owner: DeviceNavigationEngine<Request>?
    following = RouteFollowingEngine(route: route, onChange: { state in owner?.changed(state) })
    self.location = location
    self.voice = voice
    owner = self
  }

  /// state is the navigation as it stands, `NavigationState.idle` before the first command.
  public var state: NavigationState { following.state }

  /// subscribe returns a stream that yields the state as it is now, then every state that
  /// differs from the one before it, in order, until `close()`.
  public func subscribe() -> AsyncStream<NavigationState> { following.subscribe() }

  /// start asks for a route to follow, and follows it once it lands; the first start, and the
  /// first after a stop, starts the location source, unless the start's own state closed the
  /// engine.
  public func start(_ request: Request) {
    guard !closed else { return }
    following.start(request)
    // An observer the start's state is told to may close the engine before it returns, which then
    // starts no source that nothing would stop.
    guard !locating, !closed else { return }
    locating = true
    location.start { [weak self] position in try self?.setPosition(position) }
  }

  /// reroute asks for a new route where the navigation is `off-route`, and does nothing in any
  /// other status.
  public func reroute(_ request: Request) {
    guard !closed else { return }
    following.reroute(request)
  }

  /// setPosition states where the traveller is and reads it against the route followed, or keeps
  /// it for the route that lands next, and says the prompt it finds due. It throws a
  /// `PositionError` where the position names no place, and changes nothing.
  public func setPosition(_ position: [Double]) throws(PositionError) {
    guard !closed else { return }
    try following.setPosition(position)
    holdsPosition = true
  }

  /// stop ends the navigation, abandoning the request in flight and the one waiting, stopping
  /// the location source and what the voice says. The last position is kept, and read against
  /// the next route that lands.
  public func stop() {
    guard !closed else { return }
    halting = true
    following.stop()
    halting = false
    halt()
  }

  /// close stops the navigation, ends every stream, and makes every later command do nothing.
  public func close() {
    guard !closed else { return }
    closed = true
    following.close()
    halt()
  }

  /// changed is told each state the machine commits, in order and before any stream is: the
  /// guidance keeps to its route, the location source is told of a route that lands, and the
  /// prompt due is said.
  private func changed(_ state: NavigationState) {
    guard !closed, !halting else { return }
    if follow(state.route) {
      location.follow(state.route)
    }
    // A route that lands while a position is held is read at that position next, and guided
    // there, so the route unread says no prompt.
    if state.route != nil, state.progress == nil, holdsPosition { return }
    guide(state)
  }

  /// follow keeps the guidance to `route`, the route the machine follows, and answers whether it
  /// is another than the one guided: then the voice is hushed, the route laid out afresh, and
  /// nothing of it said yet.
  private func follow(_ route: FollowedRoute?) -> Bool {
    guard route != self.route else { return false }
    self.route = route
    plan = route.flatMap(guidancePlanOf)
    said = []
    voice.hush()
    return true
  }

  /// guide says the prompt due in `state`, where the navigation is `navigating` and that prompt
  /// was not said before on the route guided.
  private func guide(_ state: NavigationState) {
    guard let plan, state.status == .navigating,
      let prompt = duePrompt(plan, progress: state.progress), said.insert(prompt.id).inserted
    else { return }
    voice.say(prompt.instruction)
  }

  /// halt stops the positions and what is being said, and forgets the route guided.
  private func halt() {
    if locating {
      locating = false
      location.stop()
    }
    route = nil
    plan = nil
    said = []
    voice.hush()
    location.follow(nil)
  }
}
