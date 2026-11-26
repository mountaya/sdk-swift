// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A labelled external link attached to a waypoint.
  public struct WaypointLink: Sendable, Hashable, Codable {
    /// Text shown for the link. Trimmed of leading and trailing whitespace, and
    /// refused with a 400 when nothing is left.
    public var label: String
    /// Absolute `http` or `https` URL the link points to. Any other scheme is
    /// rejected: a renderer turns this into a link a reader clicks or an image a
    /// browser loads, so `javascript:` and `data:` are refused at the API rather
    /// than left for each client to remember.
    public var url: URI

    /// Creates a `WaypointLink` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      label: String,
      url: URI,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.label = label
      self.url = url
      configure(&self)
    }

    /// Reads a `WaypointLink` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.label = try container.decode(String.self, forKey: "label")
      self.url = try container.decodeWired(URI.self, forKey: "url")
    }

    /// Writes a `WaypointLink` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.label, forKey: "label")
      try container.encodeWired(self.url, forKey: "url")
    }
  }
}
