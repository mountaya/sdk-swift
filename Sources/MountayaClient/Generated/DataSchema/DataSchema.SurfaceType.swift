// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Classification of the ground surface a stretch of route is carried on: what it
  /// is paved with, rather than the character of the way.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct SurfaceType: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Unknown or unclassified surface.
    public static let unknown: Self = "UNKNOWN"
    /// Generic paved surface.
    public static let paved: Self = "PAVED"
    /// Generic unpaved surface.
    public static let unpaved: Self = "UNPAVED"
    /// Asphalt surface.
    public static let asphalt: Self = "ASPHALT"
    /// Concrete surface.
    public static let concrete: Self = "CONCRETE"
    /// Cobblestone surface.
    public static let cobblestone: Self = "COBBLESTONE"
    /// Metal surface.
    public static let metal: Self = "METAL"
    /// Wooden surface.
    public static let wood: Self = "WOOD"
    /// Compacted gravel surface.
    public static let compactedGravel: Self = "COMPACTED_GRAVEL"
    /// Fine gravel surface.
    public static let fineGravel: Self = "FINE_GRAVEL"
    /// Gravel surface.
    public static let gravel: Self = "GRAVEL"
    /// Dirt surface.
    public static let dirt: Self = "DIRT"
    /// Natural ground surface.
    public static let ground: Self = "GROUND"
    /// Ice surface.
    public static let ice: Self = "ICE"
    /// Paving stones surface.
    public static let pavingStones: Self = "PAVING_STONES"
    /// Sand surface.
    public static let sand: Self = "SAND"
    /// Woodchips surface.
    public static let woodchips: Self = "WOODCHIPS"
    /// Grass surface.
    public static let grass: Self = "GRASS"
    /// Grass paver surface.
    public static let grassPaver: Self = "GRASS_PAVER"

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
