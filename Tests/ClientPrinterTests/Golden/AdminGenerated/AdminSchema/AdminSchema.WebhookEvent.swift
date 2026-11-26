// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A change recorded, as it is delivered to an endpoint.
  public struct WebhookEvent: Sendable, Hashable, Codable {
    /// Identifier of the event.
    public var id: String
    /// Always `webhook_event`.
    ///
    /// It is always "webhook_event", which this type writes itself.
    public var object: String {
      "webhook_event"
    }
    /// What happened.
    public var type: AdminSchema.WebhookEventType
    /// When the change was made.
    public var created_at: Date
    /// The object, and what the change moved.
    public var data: AdminSchema.WebhookEventData
    /// The request that made the change, null for a change made on its own.
    public var request_id: String?
    /// Whether the change was made in a live organization.
    public var livemode: Bool?
    /// The former identifier of the event. Use `id` instead.
    @available(*, deprecated, message: "The former identifier of the event.")
    public var legacy_id: String? {
      get { _legacy_id }
      set { _legacy_id = newValue }
    }

    var _legacy_id: String?

    /// Creates a `WebhookEvent` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      id: String,
      type: AdminSchema.WebhookEventType,
      created_at: Date,
      data: AdminSchema.WebhookEventData,
      request_id: String?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.type = type
      self.created_at = created_at
      self.data = data
      self.request_id = request_id
      self.livemode = nil
      self._legacy_id = nil
      configure(&self)
    }

    /// Reads a `WebhookEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.type = try container.decode(AdminSchema.WebhookEventType.self, forKey: "type")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.data = try container.decode(AdminSchema.WebhookEventData.self, forKey: "data")
      self.request_id = try container.decodeIfPresent(String.self, forKey: "request_id")
      self.livemode = try container.decodeIfPresent(Bool.self, forKey: "livemode")
      self._legacy_id = try container.decodeIfPresent(String.self, forKey: "legacy_id")
    }

    /// Writes a `WebhookEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.object, forKey: "object")
      try container.encode(self.type, forKey: "type")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.data, forKey: "data")
      try container.encodeNullable(self.request_id, forKey: "request_id")
      try container.encodeIfPresent(self.livemode, forKey: "livemode")
      try container.encodeIfPresent(self._legacy_id, forKey: "legacy_id")
    }
  }
}
