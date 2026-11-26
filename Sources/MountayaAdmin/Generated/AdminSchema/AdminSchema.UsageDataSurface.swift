// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Where a day's data usage was made. Only `api` and `mcp`, the organization's
  /// own clients, count toward the Data API's per-minute limit, its monthly
  /// allowance and its invoice. `studio-online` and `studio-embedded` are
  /// Mountaya's own editors at work for the organization: they are recorded so
  /// the organization can see them and are never counted, held instead to the
  /// bounds the Data API states for them. A request made with a session token
  /// minted for `studio-embedded` is `studio-embedded` only while the
  /// organization holds Embedded Studio, and is recorded and counted as `api`
  /// while it does not.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct UsageDataSurface: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// A request to the Data API under one of the organization's keys, with a session token minted
    /// for the `api` surface. Counted.
    public static let api: Self = "api"
    /// A request made through Mountaya's MCP server on the organization's behalf. Counted.
    public static let mcp: Self = "mcp"
    /// The work Map Studio in Mountaya's web application did for a person signed in to it, recorded
    /// under the organization the studio had open when that person is a member of it: the routing a
    /// Map Studio write made (a routed segment, an import preview and confirm, or a zone computed
    /// from a source) and the studio's own Data API requests. Never counted.
    public static let studioOnline: Self = "studio-online"
    /// The work an Embedded Studio did for the organization under one of its keys: the routing a
    /// Map Studio write made (a routed segment, an import preview and confirm, or a zone computed
    /// from a source), and every Data API request made with a session token minted for the
    /// `studio-embedded` surface while the organization holds Embedded Studio. Never counted.
    public static let studioEmbedded: Self = "studio-embedded"

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
