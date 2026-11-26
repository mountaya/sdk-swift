// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Why a stream ended with a `reconnect` event. A stream ends when the credential
  /// it was opened with does, or when the server cannot keep delivering it, and
  /// says which way it ended, so a client knows to reopen it at once, with a fresh
  /// credential where the credential ended (a new session token, or a new sign-in
  /// to Mountaya's web application), rather than treat the close as a failure.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct StreamReconnectReason: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The session token the stream was opened with reached its expiry, or, in Mountaya's web
    /// application, the sign-in session the stream was opened under did.
    public static let credentialExpired: Self = "credential-expired"
    /// The publishable key the stream was opened with was revoked, its organization was canceled,
    /// the key lost the scope the stream takes, or its organization lost Embedded Studio, or the
    /// Map Studio a collaboration or organization stream needs beside it; in Mountaya's web
    /// application, the sign-in session the stream was opened under was signed out, revoked or
    /// expired.
    public static let credentialRevoked: Self = "credential-revoked"
    /// The server could not keep delivering this stream's events, because the reader fell behind or
    /// the server's subscription was lost. Reopen at once with `Last-Event-ID`, with the credential
    /// already held, and the durable events written in between are replayed, so nothing durable is
    /// missed.
    public static let interrupted: Self = "interrupted"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
