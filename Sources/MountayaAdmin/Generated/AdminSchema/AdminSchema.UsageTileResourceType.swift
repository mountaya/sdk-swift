// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What a Tile API request asked for, as the usage report groups it. The values
  /// follow the tile routes, which is why two of them are plural: `itineraries` is
  /// the aggregate layer covering every itinerary, where `itinerary` is one
  /// itinerary's own geometry.
  ///
  /// Every figure names the resource its request asked for, a request refused or
  /// failed in the checks before its route ran included, on the products the
  /// organization's agreement grants, the key's scope or the rate limit: it is
  /// recorded under the resource its address names. A request that names none is
  /// counted nowhere: an address no route serves, an identifier that does not
  /// parse, and an overlay or a terrain the catalog does not list. Nor is a
  /// request refused for its key, its session token or its calling page.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct UsageTileResourceType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Tiles for ONE itinerary's geometry, counted from getItineraryTile.
    public static let itinerary: Self = "itinerary"
    /// Tiles for the aggregate layer covering EVERY itinerary the caller reaches, counted from
    /// getItinerariesTile.
    public static let itineraries: Self = "itineraries"
    /// Zone tiles.
    public static let zones: Self = "zones"
    /// Overlay tiles, such as hillshade or snow depth.
    public static let overlay: Self = "overlay"
    /// Tiles for the contents of one collection.
    public static let collection: Self = "collection"
    /// The base map, served through the Tile API: a terrain's style, TileJSON documents and tiles,
    /// the tiles of the sources its style draws, its sprites and glyphs, and the elevation raster.
    /// Recorded so the organization sees what its maps draw, and never counted toward its
    /// per-minute limit or its monthly allowance, whatever surface the request comes from. A
    /// base-map request refused, or failed, in the checks before its route ran is recorded here
    /// too, unless it names a terrain the catalog does not list, which is counted nowhere.
    public static let terrain: Self = "terrain"

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
