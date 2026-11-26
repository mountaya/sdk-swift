/// LocationRate is how often a `DeviceLocationSource` reads the device, the host's choice.
///
/// `navigation`, the default, reads every fix the platform reads for a navigation. `walking` reads
/// fewer for a traveller on foot, a fix once the device has moved 5 m: a maneuver's prompt falls due
/// 55 m before it, its 50 m trigger plus the 5 m of slack it is read with
/// (`geo.navigation.prompts`), so the fix that says it on time still lands between 55 and 50 m
/// before the maneuver. Both read the location as a fitness activity and never let the platform
/// pause the updates on its own. `sdk-kotlin` spells the two `Navigation` and `Walking`, and
/// `sdk-dart` as Swift does.
public enum LocationRate: String, CaseIterable, Sendable {
  /// navigation reads every fix the platform reads for a navigation: on Apple platforms at
  /// `kCLLocationAccuracyBestForNavigation`, with no distance filter.
  case navigation
  /// walking reads fewer fixes, for a traveller on foot: on Apple platforms at
  /// `kCLLocationAccuracyBest`, with a 5 m distance filter.
  case walking
}
