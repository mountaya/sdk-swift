// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Why an import preview recommends `linestring` rather than `directions` for a
  /// proposed segment. None of them is an error: the linestring candidate always
  /// reproduces the file, and each value says why routing it would not.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ImportRecommendationReason: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// No route could be computed along this part of the track, in whole or in part, because the
    /// routing engine found none or because it failed on Mountaya's side. A failure is recorded
    /// against the organization as a failed `directions` request on the surface the preview was
    /// made from, never billed, and a preview sent again once routing recovers may route the part.
    /// A preview none of whose parts could be routed because routing failed on Mountaya's side is
    /// not answered with this reason but with a `500`.
    public static let routeFailed: Self = "route-failed"
    /// The itinerary's activity is not routed, so a linestring is the only faithful form and no
    /// directions candidate is offered.
    public static let directionsUnsupported: Self = "directions-unsupported"
    /// A route was computed, and it strays too far from the recorded track or differs too much from
    /// it in length.
    public static let routeDeviates: Self = "route-deviates"
    /// The recorded track leaves the routable network for too much of its length, or for too long a
    /// stretch at once.
    public static let offTrail: Self = "off-trail"

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
