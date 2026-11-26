// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What a webhook event says about its object.
  public struct WebhookEventData: Sendable, Hashable, Codable {
    /// The object once the change was made.
    public var object: AdminSchema.WebhookEventObject
    /// The fields of `data.object` the change moved, each with the value it held before.
    public var previous_attributes: [String: JSONValue]?

    /// Creates a `WebhookEventData` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      object: AdminSchema.WebhookEventObject,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.object = object
      self.previous_attributes = nil
      configure(&self)
    }

    /// Reads a `WebhookEventData` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.object = try container.decode(AdminSchema.WebhookEventObject.self, forKey: "object")
      self.previous_attributes = try container.decodeIfPresent(
        [String: JSONValue].self, forKey: "previous_attributes")
    }

    /// Writes a `WebhookEventData` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encodeIfPresent(self.previous_attributes, forKey: "previous_attributes")
    }
  }
}
