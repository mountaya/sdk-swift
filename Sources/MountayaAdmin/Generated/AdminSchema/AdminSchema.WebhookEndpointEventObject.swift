// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A webhook endpoint as a webhook event carries it: its identifiers, the host of its
  /// URL, its status and its version. Its URL is never carried, since a receiver's URL is
  /// often a credential of its own, and neither are its secret and the event types it is
  /// sent: `getOrganizationWebhookEndpoint` reads them.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct WebhookEndpointEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.webhook_endpoint`: the family of
    /// the event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `organization.webhook_endpoint`, the discriminator value naming this member of
    /// its union.
    public var object: String {
      "organization.webhook_endpoint"
    }
    /// Identifier of the endpoint.
    public var id: String
    /// Identifier of the organization the endpoint belongs to.
    public var organization_id: String
    /// The host of the URL Mountaya delivers the endpoint's events to, with its port
    /// when the URL names one: never its path, its query or the credentials it may
    /// carry, which a receiver's URL often uses as its secret.
    public var host: String
    /// Whether Mountaya delivers to the endpoint once this change was made.
    public var status: AdminSchema.WebhookEndpointStatus
    /// Why the endpoint is disabled. Present while it is.
    public var disabled_reason: AdminSchema.WebhookEndpointDisabledReason?
    /// When the endpoint's run of failed deliveries began, null while its last delivery
    /// succeeded.
    public var failing_since: Date?
    /// The endpoint's version once this change was made. It climbs with every change to
    /// the endpoint's configuration and status, so of two events about one endpoint the
    /// one carrying the higher `version` is the later state: events are not delivered in
    /// order. Its health, `failing_since`, does not move it: a delivery failing or
    /// succeeding again changes no configuration, and a change asked with the endpoint's
    /// `etag` is never refused for it.
    public var version: Int64
    /// When the endpoint was created.
    public var created_at: Date
    /// When the endpoint's configuration or status last changed. Its health,
    /// `failing_since`, does not move it.
    public var updated_at: Date

    /// Creates a `WebhookEndpointEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      host: String,
      status: AdminSchema.WebhookEndpointStatus,
      failing_since: Date?,
      version: Int64,
      created_at: Date,
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.host = host
      self.status = status
      self.disabled_reason = nil
      self.failing_since = failing_since
      self.version = version
      self.created_at = created_at
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `WebhookEndpointEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.host = try container.decode(String.self, forKey: "host")
      self.status = try container.decode(AdminSchema.WebhookEndpointStatus.self, forKey: "status")
      self.disabled_reason = try container.decodeIfPresent(
        AdminSchema.WebhookEndpointDisabledReason.self, forKey: "disabled_reason")
      self.failing_since = try container.decodeWiredIfPresent(Date.self, forKey: "failing_since")
      self.version = try container.decode(Int64.self, forKey: "version")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `WebhookEndpointEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.host, forKey: "host")
      try container.encode(self.status, forKey: "status")
      try container.encodeIfPresent(self.disabled_reason, forKey: "disabled_reason")
      try container.encodeWiredNullable(self.failing_since, forKey: "failing_since")
      try container.encode(self.version, forKey: "version")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
