// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The surface a session token is minted for. It is fixed when the token is
  /// minted and signed into it, so a token minted for one surface is never read
  /// as one minted for another. It decides where the token is accepted and,
  /// on the Data API and the Tile API, the usage surface every request it
  /// carries is recorded under, which is what decides whether that request
  /// counts toward the organization's limits, allowances and invoice. It does
  /// not decide what a token minted without `user_id` reads: on every surface
  /// but `mcp`, such a token reads what the publishable key alone does, the
  /// last published snapshot and never a draft, and public-only listings.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct SessionSurface: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Your own clients, and the surface a token minted without `surface` is. Accepted wherever a
    /// session token is but on the `studio-embedded` operations, which refuse it with a `401`. One
    /// minted without `user_id` reads what the publishable key alone does, and makes the
    /// `management` reads asked for no member role when its key carries `management`, so such a
    /// token minted for a key carrying `management` stays on your own backend; a token you hand to
    /// a page is minted for a key without `management`, and a backend that must read drafts mints
    /// for a member. What it reaches on the Data API and the Tile API is `api` usage, counted
    /// toward the organization's per-minute limits, its monthly allowances and its invoice.
    public static let api: Self = "api"
    /// Mountaya's MCP server, which mints its own tokens for the requests it makes on a caller's
    /// behalf. No other caller can ask for it, and neither REST surface accepts it. It is the one
    /// token that reads the organization's drafts on the Data API when minted without `user_id`.
    /// What it reaches on the Data API is `mcp` usage, counted as `api` usage is.
    public static let mcp: Self = "mcp"
    /// An Embedded Studio, the editor or its read-only viewer, mounted in your own product. Minted
    /// only for a publishable key that reaches the `studio-embedded` scope, of an organization that
    /// holds Embedded Studio, naming a member for the editor or minted without `user_id` for a
    /// viewer. It is the only token a `studio-embedded` operation accepts, and it is accepted
    /// wherever a session token is, the Map Studio API's `publishing` reads included. One minted
    /// without `user_id`, a viewer's, reads what the publishable key alone does, as every token
    /// minted without `user_id` but an `mcp` one does: the last published snapshot and never a
    /// draft, public-only listings, tiles cut from published content, and the Data API's `search`,
    /// `itinerary` and `exportItinerary` answered as the key alone. Unlike one minted for `api`, it
    /// makes no `management` read, which answers it the `401` a key alone gets. What it reaches on
    /// the Data API and the Tile API is `studio-embedded` usage, recorded and never counted toward
    /// the organization's limits, allowances or invoice, held instead to the bounds each API states
    /// for it. That holds while the organization holds Embedded Studio: while it does not, what the
    /// token reaches there is recorded and counted as `api` usage.
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
