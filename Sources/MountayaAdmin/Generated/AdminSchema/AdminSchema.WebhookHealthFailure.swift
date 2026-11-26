// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The failed attempts of one kind in a webhook reliability report.
  public struct WebhookHealthFailure: Sendable, Hashable, Codable {
    /// How the attempts failed.
    public var failure_kind: AdminSchema.WebhookFailureKind
    /// Whose the failures are, which the kind decides.
    public var failure_class: AdminSchema.WebhookFailureClass
    /// How many attempts failed this way.
    public var count: Int64

    /// Creates a `WebhookHealthFailure` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      failure_kind: AdminSchema.WebhookFailureKind,
      failure_class: AdminSchema.WebhookFailureClass,
      count: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.failure_kind = failure_kind
      self.failure_class = failure_class
      self.count = count
      configure(&self)
    }

    /// Reads a `WebhookHealthFailure` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.failure_kind = try container.decode(
        AdminSchema.WebhookFailureKind.self, forKey: "failure_kind")
      self.failure_class = try container.decode(
        AdminSchema.WebhookFailureClass.self, forKey: "failure_class")
      self.count = try container.decode(Int64.self, forKey: "count")
    }

    /// Writes a `WebhookHealthFailure` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.failure_kind, forKey: "failure_kind")
      try container.encode(self.failure_class, forKey: "failure_class")
      try container.encode(self.count, forKey: "count")
    }
  }
}
