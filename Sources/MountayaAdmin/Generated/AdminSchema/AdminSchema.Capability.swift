// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A product capability an organization holds. These are the units of access the
  /// account is entitled to, and four of them share a name with the publishable
  /// key scope they open: `publishing`, `studio-embedded`, `tiles` and `data`. A
  /// request under one of those scopes answers `402` while the organization does
  /// not hold the capability, and `data` opens the `mcp` scope as well. The other
  /// two do not. `studio-online` has no key scope of its own: it is what every
  /// change to an organization's itineraries, collections and zones needs,
  /// whichever credential sends it. `white-label` gates no request at all.
  ///
  /// `publishing` is asked beyond its scope as well, whichever credential sends
  /// the request: publishing an itinerary or a zone needs it beside
  /// `studio-online`, downloading a draft as a file needs it, and what an
  /// organization has published, its share links and its hosted embed included,
  /// is served only while it holds it.
  ///
  /// `data` is the one capability an organization obtains on its own: the first
  /// card it saves opens the metered Data API subscription, unless the customer,
  /// or that card, still owes an invoice, which is the `402` and opens nothing,
  /// and `data` is held while that subscription is in force. Every other capability is granted by
  /// the organization's agreement with Mountaya, and `data` can be granted that
  /// way as well. A new organization holds none of them.
  ///
  /// An agreement grants what each product needs beside it. Embedded Studio
  /// (`studio-embedded`) is granted with Map Studio (`studio-online`), the Tile
  /// API (`tiles`) and the Data API (`data`), since the editor it mounts edits
  /// through Map Studio, draws its map on the Tile API and asks its previews of
  /// the Data API. Map Publishing (`publishing`) is granted with the
  /// `published-itineraries` and `published-zones` limits it is held to.
  /// Mountaya does not record an agreement that leaves one of them out.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct Capability: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Map Studio, the editor, with live collaboration and the in-studio agent. Every change to an
    /// organization's itineraries, collections and zones needs it, so an organization that does not
    /// hold it reads, deletes and takes down what it has and makes nothing new. Publishing an
    /// itinerary or a zone needs Map Publishing beside it. Granted by the organization's agreement.
    /// A person's personal space, owned by no organization, is a separate matter that no
    /// organization's agreement decides.
    public static let studioOnline: Self = "studio-online"
    /// Map Publishing, for putting an organization's maps in front of people outside it. It covers
    /// publishing an itinerary or a zone, within the `published-itineraries` and `published-zones`
    /// limits the organization's agreement sets, Mountaya's hosted embed, which renders an
    /// interactive map inside another site, share links, downloading an itinerary as a route file
    /// such as GPX, the draft included, and video export. While the organization does not hold it,
    /// what it has published is withdrawn rather than refused, its share links, its hosted embed
    /// and its published snapshots answering as if nothing were published, and taking an itinerary
    /// or a zone down never needs it. Granted by the organization's agreement. The tiles Mountaya's
    /// hosted embed draws are recorded as the organization's Tile API usage on the `embedding`
    /// surface and counted toward its per-minute limit and its monthly allowance, as its own
    /// clients' tiles are.
    public static let publishing: Self = "publishing"
    /// The Tile API. Granted by the organization's agreement. The hosted embed does not need it,
    /// since the tiles it draws are gated on Map Publishing, and share-link tiles do not either;
    /// each is recorded on a surface of its own. The hosted embed's tiles count toward the
    /// organization's per-minute limit and its monthly allowance, and share-link tiles never do.
    public static let tiles: Self = "tiles"
    /// The Data API, the Agent Skills and the MCP server, which a key reaches through the `mcp`
    /// scope. Held while the metered Data API subscription the organization's first card opens is
    /// in force, or by the organization's agreement.
    public static let data: Self = "data"
    /// Embedded Studio, the editor mounted inside a customer's own product, which is what a
    /// publishable key needs to act as a member. Granted by the organization's agreement.
    public static let studioEmbedded: Self = "studio-embedded"
    /// Suppression of the Mountaya mark on an embedded map and on exported video. Granted by the
    /// organization's agreement. Tile attribution is a licence obligation and is never suppressed
    /// by it.
    public static let whiteLabel: Self = "white-label"

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
