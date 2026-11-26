// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// The closed vocabulary of `extensions.code` on an error entry.
  ///
  /// It is declared as an enum so a client can switch on it exhaustively and have the
  /// compiler say when a new code appears, rather than string-matching against a list
  /// transcribed out of a description.
  ///
  /// This API sends BAD_REQUEST, VALIDATION_FAILED, UNAUTHORIZED, PAYMENT_REQUIRED,
  /// FORBIDDEN, NOT_FOUND, METHOD_NOT_ALLOWED, PAYLOAD_TOO_LARGE, TOO_MANY_REQUESTS,
  /// INTERNAL_ERROR, NOT_IMPLEMENTED and GATEWAY_TIMEOUT. CONFLICT, BAD_GATEWAY and
  /// SERVICE_UNAVAILABLE are never sent here: they complete the vocabulary this API
  /// shares with the REST surfaces, so one switch handles all three.
  ///
  /// The GraphQL protocol's own refusals, made before any field runs, carry codes
  /// outside this enum, as the schema's introduction states: PERSISTED_QUERY_NOT_FOUND,
  /// GRAPHQL_PARSE_FAILED and GRAPHQL_VALIDATION_FAILED, DEPTH_LIMIT_EXCEEDED for an
  /// operation nested deeper than 15 levels, and COMPLEXITY_LIMIT_EXCEEDED for one
  /// over the complexity ceiling of 500.
  ///
  /// The REST surfaces also define codes this API never sends.
  /// AI_PROVIDER_NOT_CONFIGURED (on the Map Studio API) refines a 409 answered when an
  /// agent run starts, which this API cannot do. IDEMPOTENCY_KEY_IN_USE and
  /// IDEMPOTENCY_ANSWER_UNAVAILABLE (on the Map Studio API) refine the 409 of a write
  /// sent with an Idempotency-Key, whose first request is still running or whose
  /// first answer cannot be replayed, and PRECONDITION_FAILED (on the Map Studio
  /// API) is the 412 of a write whose If-Match names a version the resource has moved
  /// on from; this API takes no write, so it takes neither header.
  /// REDELIVERY_IN_PROGRESS and SECRET_ROTATION_IN_OVERLAP (on the Map Studio API)
  /// refine the 409 of a webhook endpoint's redelivery asked while another still
  /// runs, and of its signing secret's rotation asked while the secret an earlier one
  /// replaced still signs; this API takes no write. LIMIT_REACHED (on
  /// the Map Studio API) refines the 429 that refuses a ceiling rather than a limit
  /// counted over a window, and carries no Retry-After: the seats, the published
  /// itineraries, the published zones, the invitations an organization may have
  /// waiting at once (`pending-invitations`), the webhook endpoints it may hold,
  /// the allowed domains it may list or the personal space's itineraries, none of
  /// which this API reaches.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ErrorCode: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// The request was malformed: on this API, a body not sent as application/json or that does not
    /// decode as a JSON object, or a request asking to upgrade its connection. The body is never
    /// echoed back.
    public static let badRequest: Self = "BAD_REQUEST"
    /// One or more input fields were rejected. One entry is emitted per refused field, each
    /// carrying its own `path`. An input is checked in stages and a later stage runs only once the
    /// earlier ones pass, so correct what was reported and send again.
    public static let validationFailed: Self = "VALIDATION_FAILED"
    /// No publishable key, a secret key sent in its place, or an unknown or revoked key, including
    /// any key of a canceled organization; or a session token that is absent, invalid, expired or
    /// minted for another key.
    public static let unauthorized: Self = "UNAUTHORIZED"
    /// The organization does not hold the Data API, or it is billed by card and has no payment
    /// method on file. The Data API is held while the metered subscription the organization's first
    /// card opens is in force, or by the organization's agreement with Mountaya. The product is
    /// checked before the key's scope, so a key without the scope in an organization that does not
    /// hold the Data API is answered this rather than FORBIDDEN. The payment method is checked
    /// after the scope, so the same key in an organization with no payment method on file is
    /// answered FORBIDDEN. `exportItinerary` also answers it for the draft of an itinerary whose
    /// organization does not hold Map Publishing.
    public static let paymentRequired: Self = "PAYMENT_REQUIRED"
    /// The key does not carry a scope that authorizes this field, or the request's Origin or
    /// Referer is not among the organization's allowed domains.
    public static let forbidden: Self = "FORBIDDEN"
    /// The addressed resource does not exist or is not visible to your key. The two are one answer,
    /// so it never confirms that an id exists.
    public static let notFound: Self = "NOT_FOUND"
    /// The request used an HTTP method other than POST.
    public static let methodNotAllowed: Self = "METHOD_NOT_ALLOWED"
    /// Never sent by this API, which changes no state. Part of the shared vocabulary.
    public static let conflict: Self = "CONFLICT"
    /// The request body is over 32 MiB, the ceiling the Map Studio API holds most bodies to. It is
    /// refused once the credential has been checked and before anything reads the body, and no
    /// field runs. Or, as the entry of `itinerary` or `exportItinerary` in a 200 response, the
    /// itinerary holds more than 500,000 positions, more than one answer carries: that field is
    /// refused, its entry at the input as a whole rather than at any one of its fields, and the
    /// rest of the request runs.
    public static let payloadTooLarge: Self = "PAYLOAD_TOO_LARGE"
    /// A limit on the organization's requests to this API is spent, and the response carries
    /// `Retry-After`, the whole seconds until it lifts. Either its per-minute limit, 60 requests a
    /// minute unless its agreement sets another figure, which every key of the organization draws
    /// on: wait out the minute. Or its monthly allowance, 300,000 unless its agreement sets another
    /// figure or leaves it unlimited, which counts the root fields answered without an error over
    /// the organization's current billing period, the MCP server's included: every request of the
    /// organization's own clients is refused until the next billing period begins. A request made
    /// with a session token minted for studio-embedded counts toward neither, and is refused
    /// instead once a bound of its own is spent, as this API's introduction states. So is a request
    /// from Mountaya's web application, made signed in to it rather than with a key, whose session
    /// cannot be checked yet because too many sessions sent from the client's IP address have been
    /// refused within the minute: the session may be perfectly valid, which is why it is not a 401,
    /// and `Retry-After` names the seconds until the minute's window turns.
    public static let tooManyRequests: Self = "TOO_MANY_REQUESTS"
    /// An unexpected server-side failure. Opaque by construction: no field path, no metadata.
    public static let internalError: Self = "INTERNAL_ERROR"
    /// The field cannot be answered here. Sent only by `exportItinerary`, when downloads are
    /// unavailable.
    public static let notImplemented: Self = "NOT_IMPLEMENTED"
    /// Never sent by this API. Part of the shared vocabulary.
    public static let badGateway: Self = "BAD_GATEWAY"
    /// Never sent by this API. Part of the shared vocabulary.
    public static let serviceUnavailable: Self = "SERVICE_UNAVAILABLE"
    /// The request was still running when its time budget of 30 seconds ran out, and it is answered
    /// with HTTP status 504 in place of whatever was in flight, with no data. It is the same code
    /// the REST surfaces answer a spent budget with. Nothing about the request is wrong: send it
    /// again, or narrow it, a smaller matrix or fewer root fields, where it asks a lot.
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
}
