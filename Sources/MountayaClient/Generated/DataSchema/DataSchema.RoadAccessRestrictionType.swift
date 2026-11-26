// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// An access restriction tagged on a way in OpenStreetMap (the `access` key and
  /// its mode-specific variants such as `foot`), resolved for the activity's mode of
  /// travel.
  ///
  /// A stretch carries a LIST of these rather than a single value: a way can be
  /// tagged with several restrictions at once, and every one found is reported. An
  /// unrestricted stretch, the common case, is not reported at all.
  ///
  /// PERMISSIVE, AGRICULTURAL and FORESTRY are told apart from a genuine restriction
  /// only where the routing engine returns per-stretch access data. Where it returns
  /// none, the route-level warning that stands in for that data is raised by any
  /// access tag, those three included (see RouteAdvisories).
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct RoadAccessRestrictionType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Access is forbidden (`access=no`).
    public static let no: Self = "NO"
    /// Access is limited to customers of the adjoining premises (`access=customers`).
    public static let customers: Self = "CUSTOMERS"
    /// Access is limited to reaching a destination on the way itself, not passing through
    /// (`access=destination`).
    public static let destination: Self = "DESTINATION"
    /// Access is limited to deliveries (`access=delivery`).
    public static let delivery: Self = "DELIVERY"
    /// Access is limited to the owner and their guests (`access=private`).
    public static let `private`: Self = "PRIVATE"
    /// The owner tolerates passage and may withdraw it at any time (`access=permissive`). This
    /// grants access rather than restricting it, so it is reported but is not treated as a hazard.
    public static let permissive: Self = "PERMISSIVE"
    /// Access requires an individual permit (`access=permit`).
    public static let permit: Self = "PERMIT"
    /// Access is restricted without the tagging saying to whom (`access=restricted`). Treated as a
    /// genuine restriction.
    public static let restricted: Self = "RESTRICTED"
    /// The way carries an access restriction whose nature is not recorded (`access=unknown`).
    /// Treated as a genuine restriction, because an unrecorded restriction is not an absent one.
    public static let unknown: Self = "UNKNOWN"
    /// Access is limited to vehicles servicing the way or the premises on it (`access=service`).
    public static let service: Self = "SERVICE"
    /// Access is limited to agricultural traffic (`access=agricultural`). Reported so a route over
    /// a farm track is never a surprise, but NOT treated as a hazard: farm tracks are ordinary
    /// terrain on foot.
    public static let agricultural: Self = "AGRICULTURAL"
    /// Access is limited to forestry traffic (`access=forestry`). Reported but, like AGRICULTURAL,
    /// not treated as a hazard.
    public static let forestry: Self = "FORESTRY"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
