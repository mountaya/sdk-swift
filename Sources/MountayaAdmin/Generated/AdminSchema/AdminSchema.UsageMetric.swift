// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What a Data API usage figure counts. `requests` is recorded for every call
  /// that gets past the credential check, whatever it asked for; the rest are the
  /// work one kind of call did, so a metric only appears beside the resource type
  /// that can emit it, and each member below names the resource types that do. A
  /// refused request records `requests` alone, because the work the other metrics
  /// count never happened.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct UsageMetric: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Calls made, one per root field a request asks, so a request asking two records two. Every
    /// resource type records it.
    public static let requests: Self = "requests"
    /// Results handed back to the caller, recorded by `search`, `geocode`, `reverse-geocode` and
    /// `pois`.
    public static let resultsReturned: Self = "results-returned"
    /// Search targets that ran, which is fewer than the targets asked for when an earlier one
    /// already answered. Recorded by `search` alone.
    public static let targetsExecuted: Self = "targets-executed"
    /// Routes computed, recorded by `directions` and `suggestions`.
    public static let routes: Self = "routes"
    /// Waypoints supplied to a `directions` call, recorded by `directions` alone.
    public static let waypoints: Self = "waypoints"
    /// Coordinates supplied to a geometry analysis, recorded by `analyze-geometry`. It is also
    /// accepted beside `directions`, where it reports the coordinates recorded under that resource
    /// type.
    public static let coordinates: Self = "coordinates"
    /// Matrix cells computed, recorded by `matrix` alone.
    public static let elements: Self = "elements"
    /// Isochrone polygons computed, recorded by `isochrones` alone.
    public static let polygons: Self = "polygons"
    /// Elevation readings taken, which measures the work a terrain query did rather than the one
    /// request that asked for them; reported, not counted, since the Data API is counted and
    /// invoiced per call, the `requests` metric. Recorded by `terrain-samples`, `terrain-profile`
    /// and `terrain-grid`.
    public static let samples: Self = "samples"

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
