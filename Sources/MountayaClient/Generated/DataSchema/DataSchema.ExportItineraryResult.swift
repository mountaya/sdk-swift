// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A prepared itinerary download.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ExportItineraryResult: Sendable, Hashable, Codable {
    /// Signed download URL. It is valid for ten minutes, may be fetched once or many
    /// times within that window, and requires no further authentication.
    public var url: URI?
    /// Suggested file name: the itinerary's name keeping only the letters a to z and A
    /// to Z, the accented letters French uses (such as é, è, à, ç and œ), digits,
    /// spaces, dots, underscores and hyphens, trimmed, or "export" when nothing is
    /// left, followed by the extension for the requested format. A name written in
    /// another script, such as Chinese or Japanese, therefore comes out as "export".
    /// Example: "Tour du Mont-Blanc.gpx".
    public var filename: String?
    /// Format the download is encoded in, echoed from the request.
    public var format: DataSchema.ExportFormat?
    /// When the URL stops working, ten minutes after it was minted, as an RFC 3339
    /// timestamp.
    /// Example: "2026-07-28T12:10:00Z".
    public var expiresAt: Date?

    /// Creates a `ExportItineraryResult` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.url = nil
      self.filename = nil
      self.format = nil
      self.expiresAt = nil
      configure(&self)
    }

    /// Reads a `ExportItineraryResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.url = try container.decodeIfPresent(URI.self, forKey: "url")
      self.filename = try container.decodeIfPresent(String.self, forKey: "filename")
      self.format = try container.decodeIfPresent(DataSchema.ExportFormat.self, forKey: "format")
      self.expiresAt = try container.decodeWiredIfPresent(Date.self, forKey: "expiresAt")
    }

    /// Writes a `ExportItineraryResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.url, forKey: "url")
      try container.encodeIfPresent(self.filename, forKey: "filename")
      try container.encodeIfPresent(self.format, forKey: "format")
      try container.encodeWiredIfPresent(self.expiresAt, forKey: "expiresAt")
    }
  }
}
