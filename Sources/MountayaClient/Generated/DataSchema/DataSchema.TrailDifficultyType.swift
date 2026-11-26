// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Trail difficulty as tagged in OpenStreetMap. Walking activities are graded on
  /// the SAC hiking scale (`sac_scale`) and cycling activities on the mountain-biking
  /// scale (`mtb:scale`); a stretch carries a value from whichever scale matches the
  /// activity, and the value names its own scale.
  ///
  /// Most ways carry no difficulty tag at all, so UNKNOWN is the common value and
  /// means "not classified", not "easy". On the SAC hiking scale a way tagged below
  /// HIKING is reported as UNKNOWN too, because the routing engine does not tell it
  /// apart from an untagged one.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct TrailDifficultyType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// No difficulty tag on this stretch. The most common value; it carries no difficulty claim.
    public static let unknown: Self = "UNKNOWN"
    /// Hiking. Trail is well cleared; flat or slightly sloped, no fall hazard.
    public static let hiking: Self = "HIKING"
    /// Mountain hiking. Trail is continuous, may have exposed sections; sure-footedness required.
    public static let mountainHiking: Self = "MOUNTAIN_HIKING"
    /// Demanding mountain hiking. Partly exposed with fall hazard; hands occasionally needed;
    /// sure-footedness, good boots and alpine experience required.
    public static let demandingMountainHiking: Self = "DEMANDING_MOUNTAIN_HIKING"
    /// Alpine hiking. Often pathless with exposed scrambling; familiarity with exposed terrain and
    /// an ice axe may be required.
    public static let alpineHiking: Self = "ALPINE_HIKING"
    /// Demanding alpine hiking. Frequent scrambling with climbing up to UIAA grade II; high alpine
    /// experience required.
    public static let demandingAlpineHiking: Self = "DEMANDING_ALPINE_HIKING"
    /// Difficult alpine hiking. Sustained exposed scrambling and climbing; mountaineering equipment
    /// and experience required.
    public static let difficultAlpineHiking: Self = "DIFFICULT_ALPINE_HIKING"
    /// mtb:scale=0. Solid surface, mostly gravel or packed dirt; no significant obstacles.
    public static let mtb0: Self = "MTB_0"
    /// mtb:scale=1. Mostly solid with loose sections and small obstacles such as roots or stones.
    public static let mtb1: Self = "MTB_1"
    /// mtb:scale=2. Loose surface with larger roots and stones; occasional dismounting expected.
    public static let mtb2: Self = "MTB_2"
    /// mtb:scale=3. Slippery ground with large obstacles and switchbacks; advanced technique
    /// required.
    public static let mtb3: Self = "MTB_3"
    /// mtb:scale=4. Loose scree, large boulders and tight switchbacks; expert technique required.
    public static let mtb4: Self = "MTB_4"
    /// mtb:scale=5. Very steep and blocked with boulders and scree; extreme technique required.
    public static let mtb5: Self = "MTB_5"
    /// mtb:scale=6. Barely rideable; sustained extreme obstacles and exposure.
    public static let mtb6: Self = "MTB_6"

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
