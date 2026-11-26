// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

/// APIErrorCode is the code an error carries, on the error and on each of its entries: the one
/// vocabulary of every surface, the union of the Map Studio API's and the Tile API's
/// `ErrorExtensionsCode` and the Data API's `ErrorCode`.
///
/// A program branches on it, never on an entry's `message`, which is written for a person and free
/// to change.
///
/// The set is open: a value this build has never seen decodes as itself rather than failing the
/// response, and a value the contract adds is one more static member.
public struct APIErrorCode: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
  ExpressibleByStringLiteral
{
  /// `BAD_REQUEST`, as the wire spells it, which the Map Studio API, the Tile API and the Data API
  /// declare.
  public static let badRequest: Self = "BAD_REQUEST"
  /// `VALIDATION_FAILED`, as the wire spells it, which the Map Studio API, the Tile API and the
  /// Data API declare.
  public static let validationFailed: Self = "VALIDATION_FAILED"
  /// `UNAUTHORIZED`, as the wire spells it, which the Map Studio API, the Tile API and the Data API
  /// declare.
  public static let unauthorized: Self = "UNAUTHORIZED"
  /// `PAYMENT_REQUIRED`, as the wire spells it, which the Map Studio API, the Tile API and the Data
  /// API declare.
  public static let paymentRequired: Self = "PAYMENT_REQUIRED"
  /// `LIMIT_REACHED`, as the wire spells it, which the Map Studio API declares.
  public static let limitReached: Self = "LIMIT_REACHED"
  /// `FORBIDDEN`, as the wire spells it, which the Map Studio API, the Tile API and the Data API
  /// declare.
  public static let forbidden: Self = "FORBIDDEN"
  /// `NOT_FOUND`, as the wire spells it, which the Map Studio API, the Tile API and the Data API
  /// declare.
  public static let notFound: Self = "NOT_FOUND"
  /// `METHOD_NOT_ALLOWED`, as the wire spells it, which the Map Studio API, the Tile API and the
  /// Data API declare.
  public static let methodNotAllowed: Self = "METHOD_NOT_ALLOWED"
  /// `CONFLICT`, as the wire spells it, which the Map Studio API and the Data API declare.
  public static let conflict: Self = "CONFLICT"
  /// `AI_PROVIDER_NOT_CONFIGURED`, as the wire spells it, which the Map Studio API declares.
  public static let aiProviderNotConfigured: Self = "AI_PROVIDER_NOT_CONFIGURED"
  /// `IDEMPOTENCY_KEY_IN_USE`, as the wire spells it, which the Map Studio API declares.
  public static let idempotencyKeyInUse: Self = "IDEMPOTENCY_KEY_IN_USE"
  /// `IDEMPOTENCY_ANSWER_UNAVAILABLE`, as the wire spells it, which the Map Studio API declares.
  public static let idempotencyAnswerUnavailable: Self = "IDEMPOTENCY_ANSWER_UNAVAILABLE"
  /// `REDELIVERY_IN_PROGRESS`, as the wire spells it, which the Map Studio API declares.
  public static let redeliveryInProgress: Self = "REDELIVERY_IN_PROGRESS"
  /// `SECRET_ROTATION_IN_OVERLAP`, as the wire spells it, which the Map Studio API declares.
  public static let secretRotationInOverlap: Self = "SECRET_ROTATION_IN_OVERLAP"
  /// `PRECONDITION_FAILED`, as the wire spells it, which the Map Studio API declares.
  public static let preconditionFailed: Self = "PRECONDITION_FAILED"
  /// `PAYLOAD_TOO_LARGE`, as the wire spells it, which the Map Studio API and the Data API declare.
  public static let payloadTooLarge: Self = "PAYLOAD_TOO_LARGE"
  /// `TOO_MANY_REQUESTS`, as the wire spells it, which the Map Studio API, the Tile API and the
  /// Data API declare.
  public static let tooManyRequests: Self = "TOO_MANY_REQUESTS"
  /// `INTERNAL_ERROR`, as the wire spells it, which the Map Studio API, the Tile API and the Data
  /// API declare.
  public static let internalError: Self = "INTERNAL_ERROR"
  /// `NOT_IMPLEMENTED`, as the wire spells it, which the Map Studio API and the Data API declare.
  public static let notImplemented: Self = "NOT_IMPLEMENTED"
  /// `BAD_GATEWAY`, as the wire spells it, which the Map Studio API and the Data API declare.
  public static let badGateway: Self = "BAD_GATEWAY"
  /// `SERVICE_UNAVAILABLE`, as the wire spells it, which the Map Studio API and the Data API
  /// declare.
  public static let serviceUnavailable: Self = "SERVICE_UNAVAILABLE"
  /// `GATEWAY_TIMEOUT`, as the wire spells it, which the Map Studio API, the Tile API and the Data
  /// API declare.
  public static let gatewayTimeout: Self = "GATEWAY_TIMEOUT"

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
