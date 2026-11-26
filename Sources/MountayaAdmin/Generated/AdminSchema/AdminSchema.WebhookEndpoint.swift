// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A webhook endpoint: a URL of the organization's own that Mountaya delivers
  /// webhook events to, signed with the endpoint's secret. The secret is answered
  /// once, by `postOrganizationWebhookEndpoint`, and never by a read.
  public struct WebhookEndpoint: Sendable, Hashable, Codable {
    /// Identifier of the endpoint, the `webhook_endpoint_id` a delivery names.
    public var id: String
    /// Identifier of the organization the endpoint belongs to.
    public var organization_id: String
    /// The URL Mountaya delivers to: `https`, on a host that resolves to a public
    /// address, answered within 10 seconds. A redirect is never followed.
    public var url: URI
    /// What the endpoint is for, as the organization wrote it, null when it has
    /// none.
    public var description: String?
    /// The event types the endpoint is sent: each a member of
    /// `WebhookEventType`, a family followed by `.*` for every type of the
    /// family, such as `organization.member.*`, or `*` for every public type,
    /// those added to the contract later included.
    public var enabled_events: [String]
    /// Whether Mountaya delivers to the endpoint.
    public var status: AdminSchema.WebhookEndpointStatus
    /// Why the endpoint is disabled, null while it is enabled.
    public var disabled_reason: AdminSchema.WebhookEndpointDisabledReason?
    /// When the endpoint was disabled, null while it is enabled.
    public var disabled_at: Date?
    /// When the endpoint's run of failed deliveries began, null while its last
    /// delivery succeeded. At 24 hours Mountaya records
    /// `organization.webhook_endpoint.failing` and emails the organization's
    /// owners and admins; at 72 hours it disables the endpoint. A delivery that
    /// succeeds after the run was reported records
    /// `organization.webhook_endpoint.recovered`. Read it before enabling a
    /// disabled endpoint again, which clears it, to redeliver from it.
    public var failing_since: Date?
    /// The version of the endpoint, the one the `ETag` of a read of it carries,
    /// opaque and compared whole. It moves on every change to the endpoint's
    /// configuration and status, and never with its health: a delivery failing or
    /// succeeding again moves `failing_since` and leaves it as it is. Send it as
    /// `If-Match` to make `patchOrganizationWebhookEndpoint` or
    /// `deleteOrganizationWebhookEndpoint` conditional.
    public var etag: String
    /// The member who created the endpoint, null when their account has been
    /// deleted.
    public var created_by: RestSchema.RelationToUser?
    /// When the endpoint was created.
    public var created_at: Date
    /// When the endpoint's configuration or status last changed. Its health,
    /// `failing_since`, does not move it.
    public var updated_at: Date

    /// Creates a `WebhookEndpoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      url: URI,
      description: String?,
      enabled_events: [String],
      status: AdminSchema.WebhookEndpointStatus,
      disabled_reason: AdminSchema.WebhookEndpointDisabledReason?,
      disabled_at: Date?,
      failing_since: Date?,
      etag: String,
      created_by: RestSchema.RelationToUser?,
      created_at: Date,
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.url = url
      self.description = description
      self.enabled_events = enabled_events
      self.status = status
      self.disabled_reason = disabled_reason
      self.disabled_at = disabled_at
      self.failing_since = failing_since
      self.etag = etag
      self.created_by = created_by
      self.created_at = created_at
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `WebhookEndpoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.url = try container.decode(URI.self, forKey: "url")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.enabled_events = try container.decode([String].self, forKey: "enabled_events")
      self.status = try container.decode(AdminSchema.WebhookEndpointStatus.self, forKey: "status")
      self.disabled_reason = try container.decodeIfPresent(
        AdminSchema.WebhookEndpointDisabledReason.self, forKey: "disabled_reason")
      self.disabled_at = try container.decodeWiredIfPresent(Date.self, forKey: "disabled_at")
      self.failing_since = try container.decodeWiredIfPresent(Date.self, forKey: "failing_since")
      self.etag = try container.decode(String.self, forKey: "etag")
      self.created_by = try container.decodeIfPresent(
        RestSchema.RelationToUser.self, forKey: "created_by")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `WebhookEndpoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.url, forKey: "url")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encode(self.enabled_events, forKey: "enabled_events")
      try container.encode(self.status, forKey: "status")
      try container.encodeNullable(self.disabled_reason, forKey: "disabled_reason")
      try container.encodeWiredNullable(self.disabled_at, forKey: "disabled_at")
      try container.encodeWiredNullable(self.failing_since, forKey: "failing_since")
      try container.encode(self.etag, forKey: "etag")
      try container.encodeNullable(self.created_by, forKey: "created_by")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
