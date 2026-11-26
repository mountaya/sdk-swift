// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A short-lived session, minted by exchanging a secret key for one and bound to
  /// the publishable key named in the request, to the surface named there, and to
  /// the user named there, if any. Its `sess_` token is what a browser surface authenticates with,
  /// what
  /// decides whether a read is served the draft or the published snapshot, and,
  /// when it names a user, what lets a request act as that member.
  ///
  /// This is the session, not the credential. `SessionToken` is the name of the
  /// security scheme a request authenticates with; this schema is what
  /// `postSession` answers, and it carries that token at `token` alongside the
  /// expiry to read instead of assuming one.
  ///
  /// It prints every property but its secrets, each printed as `<redacted>`, however it is printed
  /// (`sdk/SPEC.md` §1).
  public struct Session: Sendable, Hashable, Codable, CustomDebugStringConvertible,
    CustomReflectable
  {
    /// When the token stops being accepted: at most five minutes after the
    /// request, and sooner when `postSession` returned a token it minted moments
    /// earlier for the same publishable key, surface and user. There is no refresh
    /// operation: a new one is minted from the caller's own backend before this
    /// passes. Read this field rather than assuming the five minutes, so a
    /// client never holds a token past its end.
    public var expires_at: Date
    /// The user the token names, the `user_id` the request asked for, or null
    /// for a token minted without one. A token naming a user is what lets a
    /// request act as that user: every operation whose `x-acting-user` is
    /// `required` refuses a token that names none with a `401`. A token naming
    /// none writes nothing and reads what the publishable key alone does, the
    /// published snapshot and public-only listings; one minted for `api` also
    /// makes the `management` reads, and one minted for `studio-embedded` does
    /// not.
    public var user_id: String?
    /// The session token. Send it back verbatim in `X-Session-Token`. It is
    /// OPAQUE to a client: the `sess_` prefix is the only part of it this
    /// contract fixes for one. Do not parse it, do not derive an expiry from it,
    /// and read `expires_at` beside it instead. Mountaya's own SDKs read the
    /// surface it was minted for from it, so an Embedded Studio refuses a token
    /// minted for another surface before it sends anything.
    ///
    /// It is a secret: the type prints it as `<redacted>` wherever it is printed, in a log, a
    /// debugger's description or a dump, and a caller reads it as it is.
    public var token: String

    /// Creates a `Session` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      expires_at: Date,
      user_id: String?,
      token: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.expires_at = expires_at
      self.user_id = user_id
      self.token = token
      configure(&self)
    }

    /// Reads a `Session` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.expires_at = try container.decodeWired(Date.self, forKey: "expires_at")
      self.user_id = try container.decodeIfPresent(String.self, forKey: "user_id")
      self.token = try container.decode(String.self, forKey: "token")
    }

    /// Writes a `Session` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWired(self.expires_at, forKey: "expires_at")
      try container.encodeNullable(self.user_id, forKey: "user_id")
      try container.encode(self.token, forKey: "token")
    }

    /// debugDescription is the value as a log may show it, which `print`, `String(describing:)` and
    /// `dump` all write: every property but its secrets, each printed as `<redacted>`.
    public var debugDescription: String {
      var fields: [String] = []
      fields.append("expires_at: \(String(reflecting: self.expires_at))")
      fields.append("user_id: \(String(reflecting: self.user_id))")
      fields.append("token: <redacted>")
      return "Session(\(fields.joined(separator: ", ")))"
    }

    /// customMirror has no children, so `dump` and a debugger's variable view print the redacted
    /// description rather than the secrets.
    public var customMirror: Mirror {
      Mirror(self, children: [], displayStyle: .struct)
    }
  }
}
