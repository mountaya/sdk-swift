// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The changes to make to a webhook endpoint. Every field is optional, and an
  /// omitted one keeps its value.
  public struct WebhookEndpointUpdateParams: Sendable, Hashable, Codable {
    /// The URL Mountaya delivers to from the next delivery on, held to the rules
    /// of a new endpoint's. A delivery still retrying is sent to it.
    public var url: URI?
    /// What the endpoint is for, at most 100 characters, trimmed. `null`
    /// clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var description: String??
    /// The event types the endpoint is sent, replacing the list whole, as a new
    /// endpoint's. The list is read when an event is handed to its deliveries, a
    /// moment after it is recorded: an event recorded just before the change may
    /// be delivered by either list, and every later one by the new.
    public var enabled_events: [String]?
    /// `disabled` stops every delivery to the endpoint, those still retrying
    /// included, with `disabled_reason` `requested`; `enabled` starts them
    /// again from the next event, and clears `failing_since`. The events
    /// recorded meanwhile are not sent on their own: `postOrganizationWebhookDelivery`
    /// redelivers them.
    public var status: AdminSchema.WebhookEndpointStatus?

    /// Creates a `WebhookEndpointUpdateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.url = nil
      self.description = nil
      self.enabled_events = nil
      self.status = nil
      configure(&self)
    }

    /// Reads a `WebhookEndpointUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.url = try container.decodeWiredIfPresent(URI.self, forKey: "url")
      self.description = try container.decodeMerge(String.self, forKey: "description")
      self.enabled_events = try container.decodeIfPresent([String].self, forKey: "enabled_events")
      self.status = try container.decodeIfPresent(
        AdminSchema.WebhookEndpointStatus.self, forKey: "status")
    }

    /// Writes a `WebhookEndpointUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWiredIfPresent(self.url, forKey: "url")
      try container.encodeMerge(self.description, forKey: "description")
      try container.encodeIfPresent(self.enabled_events, forKey: "enabled_events")
      try container.encodeIfPresent(self.status, forKey: "status")
    }
  }
}
