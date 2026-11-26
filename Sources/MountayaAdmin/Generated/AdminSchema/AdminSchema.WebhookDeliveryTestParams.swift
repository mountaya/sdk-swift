// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A test event to send an endpoint.
  public struct WebhookDeliveryTestParams: Sendable, Hashable, Codable {
    /// The type of the test event. Its payload is the example this contract
    /// gives for the type, with an `id` of its own, so a receiver can tell a
    /// test by the identifiers it carries; it is recorded nowhere else, and
    /// listed by no `getOrganizationWebhookEvents`. An endpoint is sent a test
    /// of any type, whether or not its `enabled_events` names it.
    public var type: AdminSchema.WebhookEventType

    /// Creates a `WebhookDeliveryTestParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      type: AdminSchema.WebhookEventType,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.type = type
      configure(&self)
    }

    /// Reads a `WebhookDeliveryTestParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.type = try container.decode(AdminSchema.WebhookEventType.self, forKey: "type")
    }

    /// Writes a `WebhookDeliveryTestParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
    }
  }
}
