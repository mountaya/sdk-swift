// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Single graceful-degradation entry. Emitted in SearchResult.errors when a
  /// per-target branch fails.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct SearchTargetError: Sendable, Hashable, Codable {
    /// Identifier of the target whose branch failed.
    public var target: DataSchema.SearchTarget?
    /// Why this target's branch failed. The same `extensions.code` that querying this
    /// target on its own would have emitted on the spec `errors[]` array.
    public var code: DataSchema.ErrorCode?
    /// Message describing the failure, localized by the Accept-Language header.
    public var message: String?

    /// Creates a `SearchTargetError` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.target = nil
      self.code = nil
      self.message = nil
      configure(&self)
    }

    /// Reads a `SearchTargetError` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.target = try container.decodeIfPresent(DataSchema.SearchTarget.self, forKey: "target")
      self.code = try container.decodeIfPresent(DataSchema.ErrorCode.self, forKey: "code")
      self.message = try container.decodeIfPresent(String.self, forKey: "message")
    }

    /// Writes a `SearchTargetError` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.target, forKey: "target")
      try container.encodeIfPresent(self.code, forKey: "code")
      try container.encodeIfPresent(self.message, forKey: "message")
    }
  }
}
