// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A ceiling a write can meet, as `limit` names it on the
  /// `ResponseMetadataLimitReached` of every refusal coded `LIMIT_REACHED`. Each
  /// is a count of something the organization or the person holds, never a rate,
  /// and each is refused with a `429` that carries no `Retry-After`, since no wait
  /// lifts it: something is freed, or the organization's agreement changes.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct LimitKey: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// The domains an organization may list as allowed in its safety rules at once, 1 unless the
    /// organization's agreement says otherwise, or unlimited. An entry naming the loopback
    /// (`localhost`, a name under `.localhost`, `127.0.0.0/8` or `[::1]`) is not counted.
    public static let allowedDomains: Self = "allowed-domains"
    /// The invitations an organization may have waiting for an answer at once, 500, which no
    /// agreement changes.
    public static let pendingInvitations: Self = "pending-invitations"
    /// The itineraries a person's personal space keeps, three, which no agreement and no card
    /// changes.
    public static let personalItineraries: Self = "personal-itineraries"
    /// The itineraries an organization may have published at once, as its agreement sets.
    public static let publishedItineraries: Self = "published-itineraries"
    /// The zones an organization may have published at once, as its agreement sets.
    public static let publishedZones: Self = "published-zones"
    /// The members an organization may have, counting the invitations waiting for an answer, as its
    /// agreement sets.
    public static let seats: Self = "seats"
    /// The webhook endpoints an organization may hold at once, enabled and disabled, 2 unless the
    /// organization's agreement says otherwise, 6 at most and never unlimited.
    public static let webhookEndpoints: Self = "webhook-endpoints"

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
