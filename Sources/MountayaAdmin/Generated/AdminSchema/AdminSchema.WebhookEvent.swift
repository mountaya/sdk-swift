// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A webhook event: a change Mountaya recorded, as it is delivered to an endpoint and
  /// listed by `getOrganizationWebhookEvents`. The body of a delivery is exactly this
  /// object, and its signature covers those bytes. Every public type and the lean object it
  /// carries is an entry of this document's `webhooks`.
  public struct WebhookEvent: Sendable, Hashable, Codable {
    /// Identifier of the event. Its leading bits are the moment it was recorded, so
    /// identifiers sort by time. A delivery can arrive more than once, so a receiver
    /// deduplicates on it.
    public var id: String
    /// Always `webhook_event`.
    ///
    /// It is always "webhook_event", which this type writes itself.
    public var object: String {
      "webhook_event"
    }
    /// What happened. The family before its last dot names the kind of `data.object`.
    public var type: AdminSchema.WebhookEventType
    /// The contract version the payload follows: the `info.version` of the document that
    /// describes it.
    public var api_version: String
    /// When the change was made.
    public var created_at: Date
    /// Identifier of the organization the change was made in.
    public var organization_id: String
    /// The task that recorded the event: the resource's path and what was done, such as
    /// `organization.member.update`. The contract's `tasks.yaml` lists every task with
    /// what triggers it and the event types it records.
    public var task: String
    /// The object the event is about.
    public var related_object: AdminSchema.WebhookEventRelatedObject
    /// The object, and what the change moved.
    public var data: AdminSchema.WebhookEventData
    /// The request that made the change, a change made signed in to Mountaya's web
    /// application or by Mountaya's staff included. Null only when Mountaya made the
    /// change on its own: a schedule, work finished after a request was answered, or the
    /// payment provider's report.
    public var request: AdminSchema.WebhookEventRequest?
    /// Who made the change.
    public var actor: AdminSchema.WebhookEventActor

    /// Creates a `WebhookEvent` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      id: String,
      type: AdminSchema.WebhookEventType,
      api_version: String,
      created_at: Date,
      organization_id: String,
      task: String,
      related_object: AdminSchema.WebhookEventRelatedObject,
      data: AdminSchema.WebhookEventData,
      request: AdminSchema.WebhookEventRequest?,
      actor: AdminSchema.WebhookEventActor,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.type = type
      self.api_version = api_version
      self.created_at = created_at
      self.organization_id = organization_id
      self.task = task
      self.related_object = related_object
      self.data = data
      self.request = request
      self.actor = actor
      configure(&self)
    }

    /// Reads a `WebhookEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.type = try container.decode(AdminSchema.WebhookEventType.self, forKey: "type")
      self.api_version = try container.decode(String.self, forKey: "api_version")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.task = try container.decode(String.self, forKey: "task")
      self.related_object = try container.decode(
        AdminSchema.WebhookEventRelatedObject.self, forKey: "related_object")
      self.data = try container.decode(AdminSchema.WebhookEventData.self, forKey: "data")
      self.request = try container.decodeIfPresent(
        AdminSchema.WebhookEventRequest.self, forKey: "request")
      self.actor = try container.decode(AdminSchema.WebhookEventActor.self, forKey: "actor")
    }

    /// Writes a `WebhookEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.object, forKey: "object")
      try container.encode(self.type, forKey: "type")
      try container.encode(self.api_version, forKey: "api_version")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.task, forKey: "task")
      try container.encode(self.related_object, forKey: "related_object")
      try container.encode(self.data, forKey: "data")
      try container.encodeNullable(self.request, forKey: "request")
      try container.encode(self.actor, forKey: "actor")
    }
  }
}
