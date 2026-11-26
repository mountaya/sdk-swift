// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// What a directions request's `avoid` list actually achieved. Without it an
  /// unchanged route is ambiguous: a caller cannot tell "there was nothing to avoid"
  /// from "no route survived the constraint".
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct AvoidanceOutcome: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The request carried no `avoid` list.
    public static let notRequested: Self = "NOT_REQUESTED"
    /// Avoidance was requested and no stretch of the route was found on a named hazard, so nothing
    /// was re-routed. A hazard known only from the routing engine's route-level warning leaves no
    /// stretch to route around, so read the advisories as well.
    public static let notNeeded: Self = "NOT_NEEDED"
    /// The route returned was re-routed with the offending ways excluded, up to about 10 km of
    /// hazardous way in total, so a longer hazard can still be crossed. It may also carry a
    /// DIFFERENT hazard, so read the advisories rather than assuming.
    public static let applied: Self = "APPLIED"
    /// The hazards were found and excluded, but no route survived, so the route returned is the
    /// original one and still crosses them. Usually means a waypoint sits on the hazardous way
    /// itself, which no exclusion can route around. Also the outcome of a re-route that failed on
    /// Mountaya's side, which an INTERNAL_ERROR entry in `errors` then flags beside the route.
    public static let noRoute: Self = "NO_ROUTE"

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
