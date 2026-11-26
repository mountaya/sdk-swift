// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// An access restriction tagged in OpenStreetMap on a way a segment follows, for
  /// the itinerary activity's mode of travel. A way can carry several at once.
  /// `permissive`, `agricultural` and `forestry` are reported as information and are
  /// not hazards; every other member restricts who may pass.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct RoadAccessRestrictionType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Access is forbidden (`access=no`).
    public static let no: Self = "no"
    /// Access is limited to customers of the adjoining premises (`access=customers`).
    public static let customers: Self = "customers"
    /// Access is limited to reaching a destination on the way itself, not passing through
    /// (`access=destination`).
    public static let destination: Self = "destination"
    /// Access is limited to deliveries (`access=delivery`).
    public static let delivery: Self = "delivery"
    /// Access is limited to the owner and their guests (`access=private`).
    public static let `private`: Self = "private"
    /// The owner tolerates passage and may withdraw it at any time (`access=permissive`). This
    /// grants access rather than restricting it, so it is reported but is not treated as a hazard.
    public static let permissive: Self = "permissive"
    /// Access requires an individual permit (`access=permit`).
    public static let permit: Self = "permit"
    /// Access is restricted without the tagging saying to whom (`access=restricted`). Treated as a
    /// genuine restriction.
    public static let restricted: Self = "restricted"
    /// The way carries an access restriction whose nature is not recorded (`access=unknown`).
    /// Treated as a genuine restriction, because an unrecorded restriction is not an absent one.
    public static let unknown: Self = "unknown"
    /// Access is limited to vehicles servicing the way or the premises on it (`access=service`).
    public static let service: Self = "service"
    /// Access is limited to agricultural traffic (`access=agricultural`). Reported so a route over
    /// a farm track is never a surprise, but NOT treated as a hazard: farm tracks are ordinary
    /// terrain on foot.
    public static let agricultural: Self = "agricultural"
    /// Access is limited to forestry traffic (`access=forestry`). Reported but, like agricultural,
    /// not treated as a hazard.
    public static let forestry: Self = "forestry"

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
