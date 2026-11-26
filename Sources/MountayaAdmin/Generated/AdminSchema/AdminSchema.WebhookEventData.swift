// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What a webhook event says about its object.
  public struct WebhookEventData: Sendable, Hashable, Codable {
    /// The object once the change was made, as lean as its kind allows: identifiers and
    /// bounded figures, never geometry, a file or a credential. For a type ending in
    /// `deleted`, `revoked`, `removed` or `detached`, the object as it was, its `status`
    /// and every other member included. Where the object carries a `version`, a delete
    /// is its last version change: the `deleted` event carries a version past the last
    /// the object held, so a receiver that applies an event only when its `version` is
    /// newer applies the delete too, and never an event that arrives after it. Its
    /// `object` names its kind, which is the family of the event's type.
    public var object: AdminSchema.WebhookEventObject
    /// The fields of `data.object` the change moved, each with the value it held before.
    /// Present on the types whose entry in `webhooks` says so, such as
    /// `organization.member.updated`, which carries the member's former `role`. A field
    /// that did not move is not in it.
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
