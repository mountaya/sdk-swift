import Foundation

/// LaunchSettings is what Trail reads from its environment, the settings of the contract's
/// `sdk/trail.yaml` an app reads: each read once, as the app starts, into this one value the
/// app's root takes, so a test hands in its own.
///
/// No setting is ever committed. A build writes each into the app's Info.plist from
/// `Config/Local.xcconfig`, which git ignores, and an environment variable of the same name, set
/// in the scheme or by a test, stands over it, an empty one read as none.
struct LaunchSettings: Equatable {
  /// publishableKey is `MOUNTAYA_PUBLISHABLE_KEY`: the organization's publishable key, with the
  /// `tiles`, `publishing` and `data` scopes. Without it Trail shows its notice in place of the
  /// map and the search, and runs the rest on its demo itinerary.
  var publishableKey: String?

  /// itineraryId is `MOUNTAYA_ITINERARY_ID`: a published itinerary the key reads, shown and
  /// followed in place of the demo itinerary.
  var itineraryId: String?

  /// sessionUrl is `MOUNTAYA_SESSION_URL`: where the client posts for a session, which search
  /// needs, answered with the `Session` `postSession` mints, as `mise run trail:session` answers
  /// it. Without it search stays disabled.
  var sessionUrl: URL?

  /// replayMetersPerSecond is how fast Replay walks the route: a brisk walk's 10 m/s, and what
  /// the journey's test hands in for its own, `TRAIL_REPLAY_METERS_PER_SECOND`.
  var replayMetersPerSecond: Double = 10

  /// The variables the settings are read from.
  static let publishableKeyVariable = "MOUNTAYA_PUBLISHABLE_KEY"
  static let itineraryIdVariable = "MOUNTAYA_ITINERARY_ID"
  static let sessionUrlVariable = "MOUNTAYA_SESSION_URL"
  static let replaySpeedVariable = "TRAIL_REPLAY_METERS_PER_SECOND"

  /// read reads each setting from `environment` where it names it, and otherwise from `info`, the
  /// Info.plist the build wrote; a value of whitespace alone is none.
  static func read(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    info: [String: Any] = Bundle.main.infoDictionary ?? [:]
  ) -> LaunchSettings {
    func stated(_ variable: String) -> String? {
      let value = environment[variable] ?? info[variable] as? String
      guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty
      else { return nil }
      return trimmed
    }
    return LaunchSettings(
      publishableKey: stated(publishableKeyVariable),
      itineraryId: stated(itineraryIdVariable),
      sessionUrl: stated(sessionUrlVariable).flatMap(URL.init(string:)),
      replayMetersPerSecond: stated(replaySpeedVariable).flatMap(Double.init) ?? 10)
  }
}
