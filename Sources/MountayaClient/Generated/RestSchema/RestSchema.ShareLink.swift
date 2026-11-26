// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The share link of one itinerary or one collection: the token that opens it
  /// and when it was minted. A resource has at most one link at a time.
  ///
  /// The token grants a visitor with no key read-only access to exactly that
  /// resource, whether or not it is private: an itinerary's detail, its tiles,
  /// its export and its pace re-timed at a speed the visitor names, or a
  /// collection's detail and tiles and the itineraries and zones it contains,
  /// with what a share view needs to paint them, the organization that owns the
  /// resource and the layer and activity catalogs. It never authorizes a write
  /// or any other resource. Presented in `X-Share-Token`, or in the reserved
  /// `share_token` query parameter, it replaces the key rather than accompanying
  /// it. Rotating or removing the link has Mountaya refuse the token from the
  /// next request on; an answer a shared cache already holds for it is served
  /// until its lifetime runs out, as the rotation and the removal state. While the
  /// owning organization's agreement does not include Map Publishing the link
  /// resolves to nothing, answering `401` exactly as a removed one does, and it
  /// resolves again once the agreement includes Map Publishing.
  ///
  /// Reading, minting, rotating and removing a link all take a write role in the
  /// organization that owns the resource: handing a link out and breaking every
  /// URL already sent both act on people outside the organization. A member who
  /// can only view the resource cannot read its link, and neither can another
  /// organization's key that sees the resource only because it is public, so a
  /// link never outlives the publisher making it private. Treat the token as a
  /// secret: anyone holding it reads what it opens.
  ///
  /// It prints every property but its secrets, each printed as `<redacted>`, however it is printed
  /// (`sdk/SPEC.md` §1).
  public struct ShareLink: Sendable, Hashable, Codable, CustomDebugStringConvertible,
    CustomReflectable
  {
    /// The share credential: the literal prefix `share_` followed by 32
    /// lowercase hexadecimal characters.
    ///
    /// It is a secret: the type prints it as `<redacted>` wherever it is printed, in a log, a
    /// debugger's description or a dump, and a caller reads it as it is.
    public var share_token: String
    /// When this token was minted: when the link was first made, or last
    /// rotated.
    public var created_at: Date

    /// Creates a `ShareLink` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      share_token: String,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.share_token = share_token
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `ShareLink` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.share_token = try container.decode(String.self, forKey: "share_token")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `ShareLink` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.share_token, forKey: "share_token")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }

    /// debugDescription is the value as a log may show it, which `print`, `String(describing:)` and
    /// `dump` all write: every property but its secrets, each printed as `<redacted>`.
    public var debugDescription: String {
      var fields: [String] = []
      fields.append("share_token: <redacted>")
      fields.append("created_at: \(String(reflecting: self.created_at))")
      return "ShareLink(\(fields.joined(separator: ", ")))"
    }

    /// customMirror has no children, so `dump` and a debugger's variable view print the redacted
    /// description rather than the secrets.
    public var customMirror: Mirror {
      Mirror(self, children: [], displayStyle: .struct)
    }
  }
}
