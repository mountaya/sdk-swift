import CoreLocation
import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo
import MountayaNavigation
import Observation
import UIKit

/// AppModel is everything Trail's one screen runs on, made once from the settings the app read as
/// it started: the client, the map, the itinerary and its cache, the voice and the device's
/// positions, and the navigation running, if any. The views read it, and it is observable, so a
/// view is drawn again when what it read changes. It is bound to the main actor, where SwiftUI
/// reads it.
@MainActor
@Observable
final class AppModel {
  /// settings is what the app read as it started, or what a test handed in.
  let settings: LaunchSettings

  /// language is the language the device's reader prefers first, which the client, the units and
  /// the voice speak.
  let language: String

  /// timeZone is the device's time zone, which every date on screen is written in.
  let timeZone: String

  // trail: trail.profile
  /// cutoff is how the profile and the waypoint table write a place's cut-off: its date, medium,
  /// and its time of day, short, in the device's time zone. It is nil where the locale services
  /// know no zone of that name, so both leave every cut-off out rather than write one in another
  /// zone or form; the zone iOS keeps is always one they know, so on a device each is written.
  let cutoff: ((Date) -> String)?

  /// mountaya is the app's one client, nil where no publishable key is set.
  let mountaya: Mountaya?

  /// sessions mints the session tokens search needs, nil where no session URL is set.
  let sessions: SessionTokenEngine?

  /// map is the map's engine, nil where no publishable key is set.
  let map: MapEngine?

  /// itinerary is where the itinerary comes from, and itineraries the one cache over it, which
  /// the map, the profile, the tables and the navigation read.
  let itinerary: ItineraryReader
  let itineraries: ItineraryResourceCache

  /// itineraryId is the itinerary shown and followed: the one `MOUNTAYA_ITINERARY_ID` names where
  /// a key reads it, and the demo's otherwise.
  let itineraryId: String?

  /// voice says each maneuver, and device reads the device's positions, both kept from one
  /// navigation to the next.
  let voice: SpeechNavigationVoice
  let device: DeviceLocationSource

  /// units are what the preferences panel picks, which every figure on screen is written in.
  var units: UnitPreferences

  /// openPanel is the map's panel open, if any.
  var openPanel: MapPanel?

  /// isReplaying is whether the next navigation walks the route rather than reading the device.
  var isReplaying = false

  /// isExpanded is whether the sheet shows the itinerary's tables.
  var isExpanded = false

  /// run is the navigation running, from Start to Stop.
  private(set) var run: NavigationRun?

  @ObservationIgnored private let access = CLLocationManager()
  @ObservationIgnored private var isMapReady = false
  @ObservationIgnored private var drawnId: String?
  @ObservationIgnored private var framedId: String?

  /// Creates everything over `settings`.
  init(settings: LaunchSettings) {
    self.settings = settings
    let language = Locale.preferredLanguages.first ?? "en"
    self.language = language
    let timeZone = TimeZone.current.identifier
    self.timeZone = timeZone
    cutoff = Self.cutoffWriter(language: language, timeZone: timeZone)
    units = UnitPreferences(language: language)

    // trail: trail.client
    let sessions = settings.sessionUrl.map { address in
      SessionTokenEngine { try await mintSession(at: address) }
    }
    self.sessions = sessions
    let mountaya = settings.publishableKey.flatMap { key in
      try? Mountaya(
        credential: .publishable(key: key, sessionToken: sessions.map { .source($0) }),
        language: language)
    }
    self.mountaya = mountaya

    // trail: trail.map
    map = mountaya.map { MapEngine(client: $0, geolocation: DeviceGeolocation()) }

    // trail: trail.itinerary
    let itinerary = ItineraryReader(mountaya: mountaya)
    self.itinerary = itinerary
    itineraries = ItineraryResourceCache { id, surface in
      try await itinerary.read(id, surface: surface)
    }
    itineraryId = (mountaya == nil ? nil : settings.itineraryId) ?? itinerary.demoId

    // trail: trail.voice
    voice = SpeechNavigationVoice(language: language, fallbackLanguage: "en") { instruction in
      sentence(for: instruction)
    }

    // trail: trail.location
    device = DeviceLocationSource(rate: .walking)
  }

  // trail: trail.map
  /// showTerrain shows the Tile API's first terrain on the map. A catalogue the API refuses is held
  /// by the map itself, `MapState.isAccessRequired`, which the notice reads, until a source it
  /// refused loads again, and a catalogue that could not be read or lists no terrain leaves the base
  /// map as it was, which is all Trail would do of either, so no failure is kept here.
  func showTerrain() async {
    try? await map?.setTerrain()
  }

  // trail: trail.itinerary
  /// drawItinerary draws the itinerary the cache holds on the map once it resolves, and frames it.
  func drawItinerary() async {
    guard let map, let id = itineraryId else { return }
    let shown = ItineraryResourceEngine(cache: itineraries, itineraryId: id)
    defer { shown.close() }
    for await resource in shown.subscribe() {
      guard case .resolved = resource, let held = itinerary.held(id), drawnId != id else {
        continue
      }
      ItineraryReader.draw(held, on: map)
      drawnId = id
      frameItinerary()
    }
  }

  /// mapIsReady frames the itinerary drawn once the map has a canvas to frame it on.
  func mapIsReady() {
    isMapReady = true
    frameItinerary()
  }

  private func frameItinerary() {
    guard let map, isMapReady, let id = drawnId, framedId != id, let held = itinerary.held(id)
    else { return }
    framedId = id
    ItineraryReader.frame(held, on: map)
  }

  // trail: trail.navigation
  /// start follows the itinerary shown end to end with one engine: on the replay while Replay is
  /// on, and otherwise on the device's positions, asking for when-in-use location access first.
  func start() {
    guard run == nil, let id = itineraryId else { return }
    // trail: trail.location
    let location: any LocationSource
    if isReplaying {
      location = ReplayLocationSource(metersPerSecond: settings.replayMetersPerSecond)
    } else {
      // The source reads positions once the app holds full-accuracy when-in-use access, which the
      // app asks for here, and only here, in the foreground: Trail declares no background mode.
      location = device
      if access.authorizationStatus == .notDetermined {
        access.requestWhenInUseAuthorization()
      }
    }
    let itinerary = itinerary
    let engine = DeviceNavigationEngine<String>(
      route: { id in try await itinerary.route(id) }, location: location, voice: voice)
    run = NavigationRun(engine: engine, map: map)
    // trail: trail.progress
    UIApplication.shared.isIdleTimerDisabled = true
    engine.start(id)
  }

  // trail: trail.stop
  /// stop ends the navigation wherever it stands, the engine, its positions and its voice, and
  /// shows Start again.
  func stop() {
    run?.stop()
    run = nil
    UIApplication.shared.isIdleTimerDisabled = false
  }

  // trail: trail.progress
  /// instruction is the sentence of the maneuver ahead, the departure's before the first position
  /// is read, in the words the voice says it with.
  func instruction(_ state: NavigationState) -> String? {
    guard let steps = state.route?.steps, !steps.isEmpty else { return nil }
    let ahead = state.progress.map { $0.next ?? $0.step } ?? 0
    return sentence(for: stepInstruction(steps[min(max(ahead, 0), steps.count - 1)]))
  }

  /// progress is the distance and the time left and the arrival, in the reader's units, the
  /// arrival as its time of day alone, short, in the device's time zone.
  func progress(_ state: NavigationState, now: Date = .now) -> String? {
    guard let left = state.progress?.toArrival else { return nil }
    let arrival = left.duration.flatMap { seconds in
      seconds.isFinite
        ? formatDateTime(
          now.addingTimeInterval(seconds), locale: language, timeZone: timeZone,
          timeLength: .short) : nil
    }
    return Words.progress(
      distance: formatDistance(left.distance, units: units),
      duration: formatDuration(left.duration, units: units), arrival: arrival)
  }

  /// cutoffWriter writes a cut-off as its date, medium, and its time of day, short, in `language`
  /// and `timeZone`, or is nil where the locale services know no zone of that name, so no cut-off
  /// is written at all and nothing stands in its place. They refuse a zone and never an instant,
  /// so a zone that writes one moment writes every one.
  private static func cutoffWriter(language: String, timeZone: String) -> ((Date) -> String)? {
    let written = { (date: Date) in
      formatDateTime(
        date, locale: language, timeZone: timeZone, dateLength: .medium, timeLength: .short)
    }
    guard written(Date(timeIntervalSince1970: 0)) != nil else { return nil }
    return { date in
      guard let text = written(date) else {
        preconditionFailure("the locale services knew \(timeZone) when the writer was made")
      }
      return text
    }
  }
}
