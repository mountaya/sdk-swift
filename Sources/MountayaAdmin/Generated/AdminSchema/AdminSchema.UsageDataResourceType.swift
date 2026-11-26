// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Which Data API operation a usage figure belongs to, as the usage report
  /// groups it. Each value is the Data API field it counts, spelled in kebab
  /// case as every enum published here is: lowercase, with a hyphen before each
  /// capital, so the field `reverseGeocode` is reported as `reverse-geocode` and
  /// `terrainProfile` as `terrain-profile`.
  ///
  /// Every figure names the operation its request asked for, a request refused
  /// or failed before any operation ran included: such a request is counted once
  /// under each root field its document names, at most four, the most one
  /// operation can carry, as a `requests` figure. A root field its document
  /// leaves out with `@skip(if: true)` or `@include(if: false)` written as a
  /// literal names nothing; one whose condition is a variable is counted. The
  /// refusals so counted are three. A refusal in the checks that run before any
  /// operation, on the products the organization holds, the key's scope, a
  /// missing payment method or the rate limit, and a refusal of a document that
  /// does not validate against the schema are named from the body as it was
  /// sent, when it is at most 16 KiB and its document at most 1,000 tokens: a
  /// longer one is not cut short and named, it names nothing. A refusal by the
  /// GraphQL protocol of an operation the server parsed and validated is named
  /// from that operation, whatever its size: variables that do not match what
  /// the operation declares, an operation over the complexity ceiling or nested
  /// deeper than the server admits, and an enum value spelled in another case.
  /// The variables refusal is a `422`, or a `400` under
  /// `application/graphql-response+json`; the others arrive in a `200` and are
  /// counted as a `4xx`, since nothing was served. A request that names no
  /// operation is counted nowhere: a body over 32 MiB, the `413`; a request
  /// asking to upgrade its connection, a body not sent as `application/json` or
  /// one that does not decode as a JSON object, the `400`; and, for the first two
  /// refusals above, a body over 16 KiB, a document that does not parse or holds
  /// more than 1,000 tokens, one sent as a hash that is not a SHA-256 or that the
  /// server does not hold, one whose operation cannot be selected (an
  /// `operationName` it does not hold, or several operations and none named), or
  /// one whose root fields are no Data API operation. A persisted-query miss,
  /// `PERSISTED_QUERY_NOT_FOUND`, is not counted either: the client sends the
  /// document straight after it, and that request is the one counted. Nor is a
  /// request refused for its key, its session token or its calling page.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct UsageDataResourceType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Unified search across several targets at once.
    public static let search: Self = "search"
    /// Forward geocoding, from a place name to coordinates.
    public static let geocode: Self = "geocode"
    /// Reverse geocoding, from coordinates to a place name.
    public static let reverseGeocode: Self = "reverse-geocode"
    /// Points of interest.
    public static let pois: Self = "pois"
    /// Directions between waypoints.
    public static let directions: Self = "directions"
    /// Route suggestions.
    public static let suggestions: Self = "suggestions"
    /// Time-distance matrix.
    public static let matrix: Self = "matrix"
    /// Isochrones, the polygons reachable within a budget.
    public static let isochrones: Self = "isochrones"
    /// Geometry analysis, which reads an elevation and surface profile off a line you supply.
    public static let analyzeGeometry: Self = "analyze-geometry"
    /// Elevation read at the points you name.
    public static let terrainSamples: Self = "terrain-samples"
    /// Elevation sampled along a line, as a profile.
    public static let terrainProfile: Self = "terrain-profile"
    /// Elevation sampled over a bounding box, as a grid.
    public static let terrainGrid: Self = "terrain-grid"
    /// One itinerary read in full.
    public static let itinerary: Self = "itinerary"
    /// One itinerary rendered into a file format.
    public static let exportItinerary: Self = "export-itinerary"

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
