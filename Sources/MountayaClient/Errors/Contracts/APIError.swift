import Foundation

/// APIError is an error the API answered: a response that arrived with a failing status, or a
/// Data API answer carrying errors under a success, and the entries it carried.
public struct APIError: Sendable, CustomStringConvertible {
  /// Kind is the row of the contract's error ladder a failure falls on.
  ///
  /// Each 4xx a caller acts on has a row of its own, and the whole 5xx range shares one, since
  /// a caller acts identically on every 5xx. A 402 is one row whatever its entries carry, and so
  /// are a 429 and a 409, but for the two 409s that answer the request's `Idempotency-Key` rather
  /// than the request, each a kind of conflict (`isConflict`).
  ///
  /// The ladder grows when the contract adds a row, so a `switch` over it outside this module
  /// ends in `@unknown default`.
  @nonexhaustive
  public enum Kind: Sendable, Hashable {
    /// badRequest is a 400: the request itself was rejected.
    case badRequest
    /// authentication is a 401: no valid credential, or none where one is required.
    case authentication
    /// billing is a 402: not entitled to what the call needs, billed by card with no payment
    /// method on file, or a subscription opened while invoices are still owed. Each is resolved
    /// by changing the arrangement or its billing details, never in code. A ceiling is never one:
    /// it is a `rateLimit`.
    case billing
    /// forbidden is a 403: the credential is valid and does not carry what the call needs.
    case forbidden
    /// notFound is a 404: no such resource, or none this credential can view.
    case notFound
    /// methodNotAllowed is a 405: no such method on that path.
    case methodNotAllowed
    /// conflict is a 409: a concurrent edit, a duplicate, or a state that forbids the act.
    case conflict
    /// idempotencyKeyInUse is a 409 coded `IDEMPOTENCY_KEY_IN_USE`: the first request with the
    /// call's `Idempotency-Key` has not finished, so the write may still be made. A kind of
    /// conflict.
    case idempotencyKeyInUse
    /// idempotentAnswerUnavailable is a 409 coded `IDEMPOTENCY_ANSWER_UNAVAILABLE`: the write
    /// the key was first sent with was made, and its answer cannot be given again. A kind of
    /// conflict.
    case idempotentAnswerUnavailable
    /// preconditionFailed is a 412: the tag a conditional write named is no longer the
    /// resource's.
    case preconditionFailed
    /// payloadTooLarge is a 413: a body over the operation's ceiling.
    case payloadTooLarge
    /// rateLimit is a 429: a limit counted over a window, per minute, per day or per month, is
    /// spent until the window resets, and `retryAfter` is the wait the answer names; or a ceiling
    /// is reached, the seats, the published itineraries or the published zones an arrangement
    /// allows, the invitations an organization may have waiting at once or the itineraries a
    /// personal space keeps.
    ///
    /// A ceiling's `code` reads `LIMIT_REACHED`, and its `metadata` names the ceiling with what
    /// it allows and what is held. No wait lifts a ceiling, only something freed or the
    /// arrangement changed, so the API names none, `retryAfter` is nil, and the client never
    /// repeats it. A caller tells a ceiling from a spent window by its code, never by the wait it
    /// lacks.
    case rateLimit
    /// server is any 5xx: the request arrived and the API could not answer it.
    case server
    /// data is a Data API answer carrying errors under a success status, which is an error the
    /// API answered, carrying that status.
    case data
    /// other is a status with no row of its own.
    case other

    /// name is the contract's name for the row's class, such as `PreconditionFailedError`.
    public var name: String {
      switch self {
      case .badRequest: "BadRequestError"
      case .authentication: "AuthenticationError"
      case .billing: "BillingError"
      case .forbidden: "ForbiddenError"
      case .notFound: "NotFoundError"
      case .methodNotAllowed: "MethodNotAllowedError"
      case .conflict: "ConflictError"
      case .idempotencyKeyInUse: "IdempotencyKeyInUseError"
      case .idempotentAnswerUnavailable: "IdempotentAnswerUnavailableError"
      case .preconditionFailed: "PreconditionFailedError"
      case .payloadTooLarge: "PayloadTooLargeError"
      case .rateLimit: "RateLimitError"
      case .server: "ServerError"
      case .data: "DataError"
      case .other: "ApiError"
      }
    }

    /// allNames is the contract's name of every row, the base `ApiError` included.
    static let allNames: [String] = [
      Kind.badRequest, .authentication, .billing, .forbidden, .notFound, .methodNotAllowed,
      .conflict, .idempotencyKeyInUse, .idempotentAnswerUnavailable, .preconditionFailed,
      .payloadTooLarge, .rateLimit, .server, .data, .other,
    ].map(\.name)

    /// isConflict is true for a 409 of any kind, the two that answer an `Idempotency-Key`
    /// included, which is the ladder's one subclass edge: the contract's
    /// `IdempotencyKeyInUseError` and `IdempotentAnswerUnavailableError` are `ConflictError`s.
    public var isConflict: Bool {
      switch self {
      case .conflict, .idempotencyKeyInUse, .idempotentAnswerUnavailable: true
      default: false
      }
    }
  }

  /// IdempotentAnswer is the answer a write was first given, as a 409 coded
  /// `IDEMPOTENCY_ANSWER_UNAVAILABLE` names it under `extensions.metadata`: the write was made,
  /// and this is what its caller reads the resource again from.
  public struct IdempotentAnswer: Sendable, Hashable {
    /// status is the status the write was first answered with, or nil where the metadata states
    /// no whole number there.
    public let status: Int?
    /// location is the `Location` that answer carried, or nil where the metadata states no
    /// string there.
    public let location: String?
    /// etag is the `ETag` that answer carried, or nil where the metadata states no string there.
    public let etag: String?

    /// Creates the answer a write was first given.
    public init(status: Int?, location: String?, etag: String?) {
      self.status = status
      self.location = location
      self.etag = etag
    }
  }

  /// status is the HTTP status the answer arrived with, a Data API's success status included.
  public let status: Int
  /// errors is every entry of the failure envelope, in the order the API found them. It is
  /// empty where the response carried no envelope it could be read from.
  public let errors: [ErrorEntry]
  /// kind is the row of the error ladder the status and the code fall on.
  public let kind: Kind
  /// metadata is the answer's `extensions.metadata` exactly as sent, or nil where it carries
  /// none. It tells apart two answers that share a status and a code: a 409 refused by a lock
  /// names the member holding it at `holder.id`, and one refused because another write landed
  /// first names nothing.
  public let metadata: JSONValue?
  /// retryAfter is the whole seconds the answer's `Retry-After` named, whatever its status, or
  /// nil where it named none: what a caller schedules its next call from where the client did
  /// not wait.
  public let retryAfter: Duration?
  /// requestId is the answer's `X-Request-Id` exactly as sent, the one thing a caller quotes to
  /// support, or nil where it sent none.
  public let requestId: String?
  /// rateLimit is the state the answer's `RateLimit-Policy` and `RateLimit` describe, or nil
  /// where they describe none.
  public let rateLimit: RateLimitState?
  /// etag is the answer's `ETag` exactly as sent, or nil where it sent none. On a 412 it is the
  /// resource's tag now, and not one its caller has read.
  public let etag: String?
  /// idempotencyKey is the `Idempotency-Key` the call sent, the caller's as given or the one
  /// the client drew, or nil where it sent none.
  public let idempotencyKey: String?
  /// cause is what went wrong beneath the answer, such as a body that does not decode, for
  /// diagnostics only: a caller matches on `kind`, never on it.
  public let cause: (any Error)?
  /// answeredAt is the instant the answer arrived, on the client's clock, which the wait it names
  /// is counted from, or nil for an error a caller built.
  let answeredAt: Date?
  /// declaration is what the failed call's operation declares about the credentials it takes, as
  /// far as the next step its description names turns on it.
  let declaration: NextStep.Declaration

  /// Creates the error an answer with this status, these envelope entries and these headers is.
  public init(
    status: Int,
    errors: [ErrorEntry] = [],
    metadata: JSONValue? = nil,
    retryAfter: Duration? = nil,
    requestId: String? = nil,
    rateLimit: RateLimitState? = nil,
    etag: String? = nil,
    idempotencyKey: String? = nil
  ) {
    self.init(
      kind: ErrorLadder.kind(status: status, code: errors.first?.code),
      status: status,
      errors: errors,
      metadata: metadata,
      retryAfter: retryAfter,
      requestId: requestId,
      rateLimit: rateLimit,
      etag: etag,
      idempotencyKey: idempotencyKey,
      cause: nil,
      answeredAt: nil,
      declaration: .none
    )
  }

  /// Creates an error of a row its status does not imply, such as the base `APIError` a walk
  /// raises under the 200 of a page that names a cursor already sent.
  init(
    kind: Kind,
    status: Int,
    errors: [ErrorEntry] = [],
    metadata: JSONValue? = nil,
    retryAfter: Duration? = nil,
    requestId: String? = nil,
    rateLimit: RateLimitState? = nil,
    etag: String? = nil,
    idempotencyKey: String? = nil,
    cause: (any Error)? = nil,
    answeredAt: Date? = nil,
    declaration: NextStep.Declaration = .none
  ) {
    self.kind = kind
    self.status = status
    self.errors = errors
    self.metadata = metadata
    self.retryAfter = retryAfter
    self.requestId = requestId
    self.rateLimit = rateLimit
    self.etag = etag
    self.idempotencyKey = idempotencyKey
    self.cause = cause
    self.answeredAt = answeredAt
    self.declaration = declaration
  }

  /// code is the classifying code, which is the first entry's, or nil where the error carries no
  /// entry or its first entry carries no code.
  public var code: APIErrorCode? {
    errors.first?.code
  }

  /// hasCode is whether any entry carries `code`, the first or another, since a refusal may name
  /// several codes at once: a 402 whose first entry is coded `PAYMENT_REQUIRED` answers true for
  /// `.forbidden` where a later entry carries it.
  public func hasCode(_ code: APIErrorCode) -> Bool {
    errors.contains { $0.code == code }
  }

  /// unavailableAnswer is what the API names of the answer a write was first given, where the
  /// error is a 409 coded `IDEMPOTENCY_ANSWER_UNAVAILABLE`, and nil for every other error: a
  /// status where the metadata states a whole number, a `Location` and an `ETag` where it states
  /// a string, each nil otherwise.
  public var unavailableAnswer: IdempotentAnswer? {
    guard kind == .idempotentAnswerUnavailable else { return nil }
    guard case .object(let members)? = metadata else {
      return IdempotentAnswer(status: nil, location: nil, etag: nil)
    }
    var status: Int?
    if case .number(let number)? = members["status"] {
      status = Int(exactly: number)
    }
    var location: String?
    if case .string(let text)? = members["location"] {
      location = text
    }
    var etag: String?
    if case .string(let text)? = members["etag"] {
      etag = text
    }
    return IdempotentAnswer(status: status, location: location, etag: etag)
  }

  /// carrying returns the same error carrying the key its call sent.
  func carrying(idempotencyKey key: String?) -> APIError {
    APIError(
      kind: kind,
      status: status,
      errors: errors,
      metadata: metadata,
      retryAfter: retryAfter,
      requestId: requestId,
      rateLimit: rateLimit,
      etag: etag,
      idempotencyKey: key,
      cause: cause,
      answeredAt: answeredAt,
      declaration: declaration
    )
  }

  /// message is the failure as a developer reads it: the status, the code and the first entry's
  /// message, then the next step a caller can take where the error names one, as `sdk-kotlin` and
  /// `sdk-dart` write theirs. A 429 reads `429 TOO_MANY_REQUESTS: Too many requests.`, then the
  /// wait it names.
  public var message: String {
    var text = "\(status)"
    if let code {
      text += " \(code.rawValue)"
    }
    if let said = errors.first?.message, !said.isEmpty {
      text += ": \(said)"
    }
    guard let step = nextStep else { return text }
    let ended = text.last.map { ".!?".contains($0) } ?? false
    return text + (ended ? " " : ". ") + step
  }

  /// description is the failure as a developer reads it in a log, its `message`.
  public var description: String {
    message
  }

  /// nextStep is what a caller can do about the failure, for the statuses that name one, sharpened
  /// by what the call's operation declares (`NextStep`).
  var nextStep: String? {
    NextStep.step(
      status: status,
      code: code,
      retryAfter: retryAfter,
      rateLimit: rateLimit,
      declaration: declaration,
      answeredAt: answeredAt
    )
  }
}
