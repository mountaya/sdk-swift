import Foundation
import MountayaClient
import MountayaGeo
import MountayaNavigation

/// Navigation reads the navigation product as an app does: the machine every engine stands on,
/// built over the app's own route source, the engine an app navigates with, on every platform, the
/// location sources and voices conformed from outside and the ones the product ships, and, in an
/// iOS build, the voice over the system's speech.
enum Navigation {
  /// Unrouted is what the app's route source throws where it has no route.
  struct Unrouted: Error {}

  /// route is an app's route source: one Data API call, its steps read into the vocabulary.
  static let route: NavigationRouteSource<[[Double]]> = { waypoints in
    let line = waypoints
    let steps = readDirectionsSteps(nil, coordinateCount: line.count).steps
    guard !line.isEmpty else { throw Unrouted() }
    return NavigationRoute(line: line, steps: steps, duration: nil)
  }

  /// follow follows a route on the machine itself, with positions from a replay and from the app.
  @MainActor
  static func follow() throws {
    let navigation = RouteFollowingEngine(route: route)
    let replay = ReplayLocationSource(metersPerSecond: 1.4, interval: .seconds(2))
    replay.start { position in try navigation.setPosition(position) }
    navigation.start([[6.8652, 45.9237], [6.9271, 45.9682]])
    try navigation.setPosition([6.8655, 45.9239])
    replay.follow(navigation.state.route)
    _ = (navigation.state.status, isOffRouteAt([6.9, 45.95], lines: []), offRouteMeters)
    _ = (isOffRoute(metersToRoute([6.9, 45.95], lines: [])), navigation.state.route?.measured)
    replay.stop()
    navigation.close()
    // The app's own positions, from a stack of its own, and what goes wrong with them.
    let (positions, fix) = AsyncStream.makeStream(of: [Double].self)
    let streamed = StreamLocationSource(positions) { error in _ = error is PositionError }
    fix.finish()
    let sources: [any LocationSource] = [InertLocationSource(), replay, streamed, Tracked()]
    let voices: [any NavigationVoice] = [InertNavigationVoice(), Spoken()]
    _ = (sources.count, voices.count)
    // The engine an app navigates with, on any platform: the app's positions and its own voice.
    let guided = DeviceNavigationEngine<[[Double]]>(
      route: route, location: Tracked(), voice: Spoken())
    guided.start([[6.8652, 45.9237], [6.9271, 45.9682]])
    try guided.setPosition([6.8655, 45.9239])
    guided.reroute([[6.8655, 45.9239], [6.9271, 45.9682]])
    let silent = DeviceNavigationEngine<String>(route: { _ in throw Unrouted() })
    _ = (guided.state, guided.subscribe(), silent.state)
    guided.stop()
    guided.close()
    #if canImport(CoreLocation) && !os(tvOS)
      _ = DeviceLocationSource()
      // Where the app stands on location access, read again from the answer to its own request,
      // and the screen kept reading where its Info.plist declares the mode.
      let device = DeviceLocationSource(backgroundUpdates: true) { error in
        // Every failure is a LocationError, its kinds an open set every SDK names alike.
        if let failure = error as? LocationError {
          _ = (
            failure.kind == .backgroundUndeclared, failure.kind == .audioUndeclared,
            failure.kind == LocationError.Kind(rawValue: "providerDisabled"), failure.cause,
            failure.description
          )
        }
      }
      let standing: LocationStanding = device.recheckPermission()
      _ = (
        standing == device.standing, device.standing.authorization == .whenInUse,
        device.standing.accuracy == LocationAccuracy.full, device.backgroundUpdates,
        LocationAuthorization.allCases.count
      )
    #endif
  }

  #if os(iOS)
    /// NoRoute is what the README's route source throws where the Data API answers no line.
    struct NoRoute: Error {}

    /// sentence is an app's own words for an instruction.
    static func sentence(for instruction: NavigationInstruction) -> String? {
      instruction.name.map { "Prenez \($0)" }
    }

    /// guided is the README's navigation snippet, compiled for iOS, where the device's position
    /// and its speech are read: the engine an iOS app navigates with, over the app's own client.
    @MainActor
    static func guided() throws -> DeviceNavigationEngine<[[Double]]> {
      let mountaya = try Mountaya(
        credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))

      let navigation = DeviceNavigationEngine<[[Double]]>(
        // Your route source: one Data API request, its steps read into one vocabulary.
        route: { waypoints in
          let found = try await mountaya.data.directions(
            input: .init(activity: .hikingAndTrail, waypoints: waypoints))
          guard let route = found.routes?.first, case .lineString(let line)? = route.geometry else {
            throw NoRoute()
          }
          let steps = readDirectionsSteps(route.steps, coordinateCount: line.coordinates.count)
          return NavigationRoute(
            line: line.coordinates, steps: steps.steps, duration: route.duration)
        },
        location: DeviceLocationSource(),
        // Your words for each instruction, which is a copy key and its arguments.
        voice: SpeechNavigationVoice(language: "fr-FR") { instruction in
          sentence(for: instruction)
        }
      )
      navigation.start([[6.8652, 45.9237], [6.9271, 45.9682]])
      _ = (navigation.state, navigation.subscribe())
      return navigation
    }

    /// voiced is a voice that falls back on another language where the device holds no voice for
    /// its own, prepared ahead of its first sentence and closed by the app that made it.
    @MainActor
    static func voiced() async {
      let voice = SpeechNavigationVoice(
        language: "rm-CH", fallbackLanguage: "de-CH",
        onError: { error in
          // A refusal of the audio session, the sentence said all the same.
          _ = (error as? SpeechError)?.kind == .audioRefused
        }
      ) { instruction in
        sentence(for: instruction)
      }
      await voice.prepare()
      voice.close()
    }
  #endif
}

/// Tracked is an app's own location source, conformed from outside: positions from a track it
/// recorded, and no use for the route followed. It is bound to the main actor, as every location
/// source is.
@MainActor
final class Tracked: LocationSource {
  private var deliver: (@MainActor ([Double]) throws -> Void)?

  func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {
    self.deliver = deliver
    try? deliver([6.8652, 45.9237])
  }

  func stop() {
    deliver = nil
  }
}

/// Spoken is an app's own voice, conformed from outside: it hands each instruction to the app's
/// own speech. It is bound to the main actor, as every voice is.
@MainActor
final class Spoken: NavigationVoice {
  private(set) var said: [NavigationInstructionKey] = []

  func say(_ instruction: NavigationInstruction) {
    said.append(instruction.key)
  }

  func hush() {
    said = []
  }
}
