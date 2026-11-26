// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Which ceiling a refusal coded `LIMIT_REACHED` met, at `extensions.metadata`
  /// of its `429`, with the figures it was read against, so a client can say what
  /// is full without a second read. That `429` carries no `Retry-After`: no wait
  /// lifts a ceiling.
  public struct ResponseMetadataLimitReached: Sendable, Hashable, Codable {
    /// The ceiling that refused the write.
    public var limit: RestSchema.LimitKey
    /// How many the ceiling allows.
    public var allowed: Int
    /// How many are held now, the count the write would have taken past
    /// `allowed`.
    public var used: Int

    /// Creates a `ResponseMetadataLimitReached` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      limit: RestSchema.LimitKey,
      allowed: Int,
      used: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.limit = limit
      self.allowed = allowed
      self.used = used
      configure(&self)
    }

    /// Reads a `ResponseMetadataLimitReached` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.limit = try container.decode(RestSchema.LimitKey.self, forKey: "limit")
      self.allowed = try container.decode(Int.self, forKey: "allowed")
      self.used = try container.decode(Int.self, forKey: "used")
    }

    /// Writes a `ResponseMetadataLimitReached` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.limit, forKey: "limit")
      try container.encode(self.allowed, forKey: "allowed")
      try container.encode(self.used, forKey: "used")
    }
  }
}
