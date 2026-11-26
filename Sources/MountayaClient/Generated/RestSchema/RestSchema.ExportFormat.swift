// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// File format for route or itinerary export. `fit` and `tcx` additionally accept
  /// an ExportVariant selecting the course or activity file type; supplying one for
  /// any other format is rejected.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ExportFormat: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// GPS Exchange Format (.gpx), compatible with most GPS devices and apps.
    public static let gpx: Self = "gpx"
    /// GeoJSON FeatureCollection (.geojson), a standard format for geographic data.
    public static let geojson: Self = "geojson"
    /// Keyhole Markup Language (.kml), the Google Earth and Maps interchange format.
    public static let kml: Self = "kml"
    /// Compressed Keyhole Markup Language (.kmz), a zipped KML document.
    public static let kmz: Self = "kmz"
    /// Flexible and Interoperable Data Transfer (.fit), the native Garmin, Wahoo and Coros format.
    /// Accepts an ExportVariant.
    public static let fit: Self = "fit"
    /// Training Center XML (.tcx), accepted by Garmin Connect, Strava and TrainingPeaks. Accepts an
    /// ExportVariant. A course's name is cut to the 15 characters the format allows, and a course
    /// point's to 10.
    public static let tcx: Self = "tcx"
    /// Comma-separated values (.csv), a flat coordinate table for spreadsheets and analysis. Lossy:
    /// segments, styling and metadata are not preserved, so a CSV export cannot be imported back. A
    /// name beginning with =, +, -, @, a tab or a carriage return, or with the full-width =, +, -
    /// or @, is prefixed with a single quote (') so a spreadsheet reads it as text.
    public static let csv: Self = "csv"

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
