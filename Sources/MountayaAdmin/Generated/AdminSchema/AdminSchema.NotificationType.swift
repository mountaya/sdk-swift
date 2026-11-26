// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A notification email Mountaya sends a person about an organization.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct NotificationType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Somebody invited the address to the organization. Sent to the address invited, always.
    public static let invitation: Self = "invitation"
    /// Somebody else changed the member's role. A security notification: always sent, and never
    /// turned off.
    public static let memberRoleChanged: Self = "member-role-changed"
    /// Somebody else removed the member from the organization. A security notification: always
    /// sent, and never turned off.
    public static let memberRemoved: Self = "member-removed"
    /// Somebody else deleted one of the organization's collections. Sent to every member, unless
    /// they turned it off.
    public static let collectionDeleted: Self = "collection-deleted"
    /// Every delivery to one of the organization's webhook endpoints has failed for 24 hours. Sent
    /// to owners and admins, unless they turned it off.
    public static let webhookEndpointFailing: Self = "webhook-endpoint-failing"
    /// One of the organization's webhook endpoints was disabled. Sent to owners and admins, unless
    /// they turned it off.
    public static let webhookEndpointDisabled: Self = "webhook-endpoint-disabled"

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
