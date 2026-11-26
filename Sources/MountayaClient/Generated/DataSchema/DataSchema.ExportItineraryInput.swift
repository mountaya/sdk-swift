// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Which itinerary to prepare a download for, and in what file format.
  ///
  /// The itinerary must be one you can already read; nothing here widens access. Only
  /// `format` and `variant` shape the file, so the same itinerary can be prepared
  /// repeatedly in different formats without side effects. `variant` applies to the two
  /// time-series formats only; supplying it with any other format is refused.
  public struct ExportItineraryInput: Sendable, Hashable, Codable {
    /// Identifier of the itinerary to export, a UUID in its canonical form of 36
    /// characters with four hyphens. Any other value, the nil UUID included, is
    /// refused with VALIDATION_FAILED at ["input", "id"].
    /// Example: "0b6d1a4e-6d3f-4f7a-9c2e-1f0a5b8c3d21".
    public var id: String
    /// File format to export.
    public var format: DataSchema.ExportFormat
    /// File type of a time-series export. Applies to FIT and TCX only: supplying it
    /// with any other format is VALIDATION_FAILED at ["input", "variant"] rather than
    /// ignored. Defaults to COURSE when omitted with FIT or TCX.
    public var variant: DataSchema.ExportVariant?

    /// Creates a `ExportItineraryInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      format: DataSchema.ExportFormat,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.format = format
      self.variant = nil
      configure(&self)
    }

    /// Reads a `ExportItineraryInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.format = try container.decode(DataSchema.ExportFormat.self, forKey: "format")
      self.variant = try container.decodeIfPresent(DataSchema.ExportVariant.self, forKey: "variant")
    }

    /// Writes a `ExportItineraryInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.format, forKey: "format")
      try container.encodeIfPresent(self.variant, forKey: "variant")
    }
  }
}
