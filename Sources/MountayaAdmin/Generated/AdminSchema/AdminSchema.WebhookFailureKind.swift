// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// How an attempt failed. `internal` is Mountaya's; every other kind is the receiver's.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WebhookFailureKind: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The endpoint did not answer within 10 seconds.
    public static let timeout: Self = "timeout"
    /// No connection could be made to the endpoint's host, or it closed before answering.
    public static let connection: Self = "connection"
    /// The endpoint's TLS was refused: a certificate that does not verify, or a version older than
    /// 1.2.
    public static let tls: Self = "tls"
    /// The endpoint answered a `3xx`, which is never followed.
    public static let redirect: Self = "redirect"
    /// The endpoint answered a status other than `2xx` or `3xx`; `response_status` names it.
    public static let httpStatus: Self = "http-status"
    /// The endpoint's host resolved to an address Mountaya never delivers to, such as a private or
    /// loopback one.
    public static let refusedAddress: Self = "refused-address"
    /// The email bounced.
    public static let bounced: Self = "bounced"
    /// The recipient's mail server does not know the address.
    public static let unknownMailbox: Self = "unknown-mailbox"
    /// The address is on a blocklist, so the email was not sent.
    public static let blocklisted: Self = "blocklisted"
    /// The recipient's mail server took the email for spam.
    public static let spam: Self = "spam"
    /// Mountaya could not make the attempt, through no fault of the receiver.
    public static let `internal`: Self = "internal"

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
