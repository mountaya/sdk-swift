// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// PostItineraryPreviewMultipartBody is the `multipart/form-data` body the contract writes
  /// inline, one part to a property.
  public struct PostItineraryPreviewMultipartBody: Sendable, Hashable {
    /// Format the upload is parsed in.
    public var provider: RestSchema.ImportProvider
    /// The uploaded itinerary file, at most 25 MiB. A larger upload is
    /// refused with `413`, and a file that cannot be read in the named
    /// provider's format, or holds no track, is a `400` naming `file`.
    public var file: Foundation.Data
    /// Identifier of the activity to use for the import, one
    /// `getActivities` lists. Required: no file format carries an
    /// activity the server reads, so there is no choice of the
    /// source's to fall back on, and a missing part is a `400` naming
    /// `activity_id`.
    public var activity_id: String
    /// Identifier of the organization the preview is scoped to: the
    /// organization a confirm will create the itinerary in, so the
    /// routing is recorded under it. It must be the key's
    /// organization; omitted, it is that organization.
    public var organization_id: String?
    /// Segmentation granularity. Optional: omit the part for `auto`,
    /// semantic splits on.
    public var granularity: RestSchema.ImportGranularity?

    /// Creates a `PostItineraryPreviewMultipartBody` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      provider: RestSchema.ImportProvider,
      file: Foundation.Data,
      activity_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.provider = provider
      self.file = file
      self.activity_id = activity_id
      self.organization_id = nil
      self.granularity = nil
      configure(&self)
    }

    /// parts is the form, as the request carries it: one part to a property, in the contract's
    /// order, and none for a property left `nil`.
    var parts: [MultipartPart] {
      var parts: [MultipartPart] = []
      parts.append(.init(name: "provider", content: .text(self.provider.rawValue)))
      parts.append(
        .init(name: "file", content: .file(self.file, contentType: "application/octet-stream")))
      parts.append(.init(name: "activity_id", content: .text(self.activity_id)))
      if let value = self.organization_id {
        parts.append(.init(name: "organization_id", content: .text(value)))
      }
      if let value = self.granularity {
        parts.append(.init(name: "granularity", content: .text(value.rawValue)))
      }
      return parts
    }
  }
}
