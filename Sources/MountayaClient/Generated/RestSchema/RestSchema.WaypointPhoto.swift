// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A photograph of the place a waypoint marks.
  public struct WaypointPhoto: Sendable, Hashable, Codable {
    /// Short caption describing the photo. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var caption: String??
    /// Absolute `http` or `https` URL of the image. Any other scheme is rejected:
    /// a renderer turns this into a link a reader clicks or an image a browser
    /// loads, so `javascript:` and `data:` are refused at the API rather than
    /// left for each client to remember.
    public var url: URI

    /// Creates a `WaypointPhoto` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      url: URI,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.caption = nil
      self.url = url
      configure(&self)
    }

    /// Reads a `WaypointPhoto` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.caption = try container.decodeMerge(String.self, forKey: "caption")
      self.url = try container.decodeWired(URI.self, forKey: "url")
    }

    /// Writes a `WaypointPhoto` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.caption, forKey: "caption")
      try container.encodeWired(self.url, forKey: "url")
    }
  }
}
