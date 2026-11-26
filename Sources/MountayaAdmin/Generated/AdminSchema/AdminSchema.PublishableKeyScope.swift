// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A scope a publishable key carries. Each one names a product, except
  /// `management`, which names the organization's own account. A key reaches
  /// nothing beyond the scopes it carries: a request under a scope it lacks answers
  /// `403`, whatever else is right about it.
  ///
  /// A scope opens its product only while the organization holds that product. A
  /// request under a scope whose product the organization does not hold answers
  /// `402`, and the product is checked before the key's scopes, so a key that
  /// lacks the scope as well is answered `402` rather than `403`.
  ///
  /// A key carries exactly the scopes it was given, and none is added because
  /// another is present. One scope INCLUDES another, which is a different thing:
  /// an operation that asks for `publishing` accepts a key carrying
  /// `studio-embedded`. `x-pkey-scope-includes` on this schema states that
  /// relation, keyed by the scope that includes and listing the scopes it
  /// includes, and it is the whole of it: no other scope includes another.
  ///
  /// A key carrying `management` carries no other scope, so a key either ships to
  /// pages, with product scopes, or administers, with `management` alone.
  /// Creating or updating a key with `management` beside another scope is a
  /// `400`, one entry per scope listed beside it.
  ///
  /// A key carrying `studio-embedded` carries `tiles` and `data` beside it, the
  /// scopes its editor's map and previews are requested under, since that scope
  /// reaches neither the Tile API nor the Data API. Neither is added for it:
  /// creating or updating a key whose list names `studio-embedded` without one of
  /// them is a `400`, one entry per missing scope, each naming `scopes`, judged
  /// with the rest of the body and before any scope's product.
  /// `x-pkey-scope-needs` on this schema states that requirement, keyed by the
  /// scope that needs and listing the scopes it needs, and it is the whole of it:
  /// no other scope needs another.
  ///
  /// On the Map Studio API the inclusion also widens which products answer. An
  /// operation that takes `publishing` passes for a key carrying `studio-embedded`
  /// when the organization holds Map Publishing, or holds Embedded Studio and Map
  /// Studio, the two products that scope belongs to, so an organization that
  /// edits its itineraries in an Embedded Studio reads them back without Map
  /// Publishing. A key carrying `publishing` alone is asked for Map Publishing. The
  /// tiles of Mountaya's hosted embed are not widened this way: on the Tile API
  /// they are checked against Map Publishing whichever of the two scopes the key
  /// carries.
  ///
  /// Two operations behind `management` carry no organization's data at all,
  /// `getAiProviders` and `getBillingProducts`, and they are there because of when
  /// they are read rather than what they hold: each is the catalog an
  /// administrator picks from while configuring the thing beside it. The catalogs
  /// an ordinary caller reads, `getActivities` and `getLayers`, take `publishing`
  /// and reach no account at all. The Tile API answers its own layer catalog,
  /// `getTileLayers`, under `tiles`, so a map drawn with the Tile API alone needs
  /// no `publishing` to find its layers.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct PublishableKeyScope: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Map Publishing. Opens Mountaya's hosted embed and reads what a published map needs,
    /// read-only. That is the layer and activity catalogs, itineraries, collections, zones and the
    /// organization itself, and an itinerary's route file. Requires Map Publishing, which the
    /// organization's agreement grants. Publishing an itinerary or a zone is not done under it:
    /// that acts as a member, so it takes `studio-embedded`, and asks for Map Publishing there. The
    /// tiles the hosted embed draws are recorded as the organization's Tile API usage on the
    /// `embedding` surface and counted toward its per-minute limit and its monthly allowance, held
    /// per client IP address as a key sent without a session token is, as the Tile API states.
    public static let publishing: Self = "publishing"
    /// Embedded Studio, the editor mounted inside your own product. Everything `publishing` reaches
    /// on the Map Studio API, plus every operation that acts as a member. That is creating,
    /// editing, publishing and sharing itineraries, collections and zones, the agent, and live
    /// collaboration. Requires two products, Embedded Studio and Map Studio, both granted by the
    /// organization's agreement, and an organization lacking either is answered `402` before the
    /// member is looked at. Publishing an itinerary or a zone, `postItineraryPublication` and
    /// `postZonePublication`, asks for Map Publishing as well. Some operations ask for Embedded
    /// Studio alone, so they answer when the agreement does not include Map Studio. They are the
    /// acts that take something down, `deleteItinerary`, `deleteItineraryPublication`,
    /// `deleteItineraryShareLink`, `deleteCollection`, `deleteCollectionItinerary`,
    /// `deleteCollectionZone`, `deleteCollectionShareLink`, `deleteZone` and
    /// `deleteZonePublication`, and the operations under `/v1/me`, which concern the person alone.
    /// The three operations on an agent run already started, `postAgentRunInput`,
    /// `getAgentRunEvents` and `postAgentRunFeedback`, ask for Embedded Studio alone as well, and
    /// leave Map Studio to the run. The run answers an input or an events connect `402` when the
    /// organization it acts in does not hold Map Studio, and closes, and a rating does not ask for
    /// Map Studio at all. A `publishing` read reached through this scope passes when the
    /// organization holds Map Publishing, or Embedded Studio and Map Studio. Every operation behind
    /// it requires a session token minted for the `studio-embedded` surface, which your own backend
    /// asks `postSession` for, and every operation that acts as a member requires that token to
    /// name the member, so a key alone acts as nobody; a token minted for any other surface is a
    /// `401` here. It reaches neither the Tile API nor the Data API: the studio's map draws its
    /// tiles under `tiles` and its search and isochrone previews ask the Data API under `data`, so
    /// its key carries those as well, and a create or update listing this scope without `tiles` or
    /// without `data` is a `400` naming `scopes`, once per missing scope. Each of those requests
    /// rides the studio's `studio-embedded` session, is recorded as `studio-embedded` usage and is
    /// never counted toward the organization's per-minute limits, its monthly allowances or its
    /// invoice, held instead to the bounds each API states for it, for as long as the organization
    /// holds Embedded Studio.
    ///
    /// It includes `publishing`: a key carrying it reaches what that scope reaches.
    ///
    /// A key carrying it carries `tiles` and `data` beside it.
    public static let studioEmbedded: Self = "studio-embedded"
    /// The Tile API, its layer catalog included. Requires the Tile API product, which the
    /// organization's agreement grants. Tiles drawn by Mountaya's hosted embed are checked against
    /// `publishing` instead, so a key carrying `tiles` alone is refused there. A request is taken
    /// for the hosted embed's when its `Origin`, or failing that its `Referer`, names a page on
    /// Mountaya's own domain, which only a browser guarantees, since a client that is not a browser
    /// sets those headers as it likes.
    public static let tiles: Self = "tiles"
    /// The Data API, queried directly. Requires the Data API product, which the organization holds
    /// once its first card has opened the metered Data API subscription, or by its agreement. It
    /// does not grant the MCP server.
    public static let data: Self = "data"
    /// Mountaya's MCP server. Requires the Data API product, held as `data` describes. It does not
    /// grant the Data API directly.
    public static let mcp: Self = "mcp"
    /// Administering the organization, meaning its keys, billing, members, settings, AI
    /// configuration, webhooks and usage. It belongs to no product. Every operation behind it also
    /// requires a session token, so a key alone never suffices. A write requires a token naming a
    /// user, the member it acts as, who holds the role the write asks. A read accepts a token
    /// minted for `api` without `user_id` and asks it for no member role, which is why such a
    /// token, minted for a key carrying this scope, stays on your own backend; one minted for
    /// `studio-embedded` without `user_id` is the `401` a key alone gets; a token naming a user is
    /// answered only while that user holds the role the read asks, and is otherwise a `403`. It
    /// carries no other scope: creating or updating a key with it beside another scope is a `400`,
    /// so the administering key is a key of its own. Never ship it in a page.
    public static let management: Self = "management"

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
