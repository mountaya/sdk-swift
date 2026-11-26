// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A webhook endpoint to create: where Mountaya delivers, and which event types
  /// it is sent.
  public struct WebhookEndpointCreateParams: Sendable, Hashable, Codable {
    /// The URL Mountaya delivers to. It is `https`, written in printable ASCII,
    /// at most 2048 characters, with no credentials before its host and no
    /// fragment, its host, port included, at most 259 characters; and that host
    /// resolves to a public address: a private, loopback or link-local one is a
    /// `400` naming `url`, and so is one that cannot be resolved.
    public var url: URI
    /// What the endpoint is for, at most 100 characters, trimmed. Omitted, the
    /// endpoint has none.
    public var description: String?
    /// The event types the endpoint is sent: each a member of
    /// `WebhookEventType`, a family followed by `.*`, or `*` for every public
    /// type, those added later included. A type or a family the contract does
    /// not publish is a `400` naming its position.
    public var enabled_events: [String]

    /// Creates a `WebhookEndpointCreateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      url: URI,
      enabled_events: [String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.url = url
      self.description = nil
      self.enabled_events = enabled_events
      configure(&self)
    }

    /// Reads a `WebhookEndpointCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.url = try container.decodeWired(URI.self, forKey: "url")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.enabled_events = try container.decode([String].self, forKey: "enabled_events")
    }

    /// Writes a `WebhookEndpointCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWired(self.url, forKey: "url")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encode(self.enabled_events, forKey: "enabled_events")
    }
  }
}
