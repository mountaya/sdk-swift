// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Which surface a tile request arrived from. `api`, the organization's own
  /// clients, and `embedding`, the Mountaya-hosted embed drawing under one of its
  /// keys, count toward the Tile API's per-minute limit and its monthly
  /// allowance, recorded apart so the organization sees each. The others are
  /// Mountaya's own surfaces drawing for the organization: they are recorded so
  /// the organization can see them and are never counted, held instead to the
  /// bounds the Tile API states for each.
  ///
  /// A tile drawn through a share link is `share`, whatever page asked for it.
  /// Under a key, a tile drawn with a session token minted for the
  /// `studio-embedded` surface is `studio-embedded` while the organization holds
  /// Embedded Studio, and `api` while it does not; one drawn inside the
  /// Mountaya-hosted embed is `embedding`, and anything else presenting the key
  /// is `api`. A tile drawn by Map Studio in Mountaya's web application, for a
  /// person signed in to it, is `studio-online`.
  ///
  /// It is one of two vocabularies spelled `surface` on this contract, and the
  /// one the caller does not choose: the server decides it from where the request
  /// arrived. `ReadSurface`, the `?surface=` query parameter, names which snapshot
  /// a read returns.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct UsageTileSurface: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// A direct Tile API call under one of the organization's keys. Counted.
    public static let api: Self = "api"
    /// A tile drawn by Map Studio in Mountaya's web application, recorded under the organization
    /// the studio had open when the person signed in to it is a member of it. Never counted.
    public static let studioOnline: Self = "studio-online"
    /// A tile drawn by an Embedded Studio, with a session token minted for the `studio-embedded`
    /// surface, while the organization holds Embedded Studio. Never counted.
    public static let studioEmbedded: Self = "studio-embedded"
    /// A tile drawn by the Mountaya-hosted embed under one of the organization's keys. Counted, as
    /// `api` is.
    public static let embedding: Self = "embedding"
    /// A tile drawn through a share link, recorded under the organization that owns the link. Never
    /// counted.
    public static let share: Self = "share"

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
