// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// PostThingUploadMultipartBody is the `multipart/form-data` body the contract writes inline, one
  /// part to a property.
  public struct PostThingUploadMultipartBody: Sendable, Hashable {
    /// The contract's `file`.
    public var file: Foundation.Data
    /// The contract's `kind`.
    public var kind: RestSchema.ThingKind
    /// The contract's `sizes`.
    public var sizes: [Int]?
    /// The contract's `note`.
    public var note: String?

    /// Creates a `PostThingUploadMultipartBody` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      file: Foundation.Data,
      kind: RestSchema.ThingKind,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.file = file
      self.kind = kind
      self.sizes = nil
      self.note = nil
      configure(&self)
    }

    /// parts is the form, as the request carries it: one part to a property, in the contract's
    /// order, and none for a property left `nil`.
    var parts: [MultipartPart] {
      var parts: [MultipartPart] = []
      parts.append(
        .init(name: "file", content: .file(self.file, contentType: "application/gpx+xml")))
      parts.append(.init(name: "kind", content: .text(self.kind.rawValue)))
      if let value = self.sizes {
        for element in value {
          parts.append(.init(name: "sizes", content: .text(String(element))))
        }
      }
      if let value = self.note {
        parts.append(.init(name: "note", content: .text(value)))
      }
      return parts
    }
  }
}
