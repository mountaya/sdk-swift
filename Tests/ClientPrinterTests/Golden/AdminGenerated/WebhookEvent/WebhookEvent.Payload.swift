// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// Payload is an event of a type this build knows: every member of the contract's envelope,
  /// `AdminSchema.WebhookEvent`, but its `type`, which the event's case names, with the `data` that
  /// type carries.
  ///
  /// `Object` is the object the type carries at `data.object`, and `PreviousAttributes` the former
  /// value of each field its change moved, `Never` for a type whose change moves none.
  public struct Payload<
    Object: Codable & Hashable & Sendable, PreviousAttributes: Codable & Hashable & Sendable
  >: Sendable, Hashable, Codable {
    /// Identifier of the event.
    public var id: String
    /// Always `webhook_event`.
    ///
    /// It is always "webhook_event", which this type writes itself.
    public var object: String {
      "webhook_event"
    }
    /// When the change was made.
    public var created_at: Date
    /// The object, and what the change moved.
    public var data: PayloadData<Object, PreviousAttributes>
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

    /// Creates a `Payload` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      id: String,
      created_at: Date,
      data: PayloadData<Object, PreviousAttributes>,
      request_id: String?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.created_at = created_at
      self.data = data
      self.request_id = request_id
      self.livemode = nil
      self._legacy_id = nil
      configure(&self)
    }

    /// Reads a `Payload` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.data = try container.decode(PayloadData<Object, PreviousAttributes>.self, forKey: "data")
      self.request_id = try container.decodeIfPresent(String.self, forKey: "request_id")
      self.livemode = try container.decodeIfPresent(Bool.self, forKey: "livemode")
      self._legacy_id = try container.decodeIfPresent(String.self, forKey: "legacy_id")
    }

    /// Writes a `Payload` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.object, forKey: "object")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.data, forKey: "data")
      try container.encodeNullable(self.request_id, forKey: "request_id")
      try container.encodeIfPresent(self.livemode, forKey: "livemode")
      try container.encodeIfPresent(self._legacy_id, forKey: "legacy_id")
    }
  }
}
