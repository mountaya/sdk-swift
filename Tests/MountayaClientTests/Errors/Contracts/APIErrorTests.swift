import Testing

@testable import MountayaClient

@Suite("APIError")
struct APIErrorTests {
  @Test("the classifying code is the first entry's, and a 402 is one class whatever it is")
  func codeIsTheFirstEntrys() {
    let error = APIError(
      status: 402,
      errors: [
        ErrorEntry(message: "The key does not reach this scope.", code: "FORBIDDEN"),
        ErrorEntry(message: "Payment is required.", code: "PAYMENT_REQUIRED"),
      ]
    )

    #expect(error.code == "FORBIDDEN")
    #expect(error.kind == .billing)
    #expect(error.errors.count == 2)
  }

  @Test("hasCode asks every entry, the first and every other, and an error with none has no code")
  func hasCodeAsksEveryEntry() {
    let error = APIError(
      status: 402,
      errors: [
        ErrorEntry(message: "Payment is required.", code: .paymentRequired),
        ErrorEntry(message: "No code."),
        ErrorEntry(message: "The key does not reach this scope.", code: .forbidden),
      ]
    )

    #expect(error.hasCode(.paymentRequired))
    #expect(error.hasCode(.forbidden))
    #expect(!error.hasCode(.notFound))
    #expect(!APIError(status: 409).hasCode(.conflict))
  }

  @Test("a code no surface declares is kept as sent, and its message writes it as the wire does")
  func undeclaredCodeKeptAsSent() {
    let error = APIError(
      status: 409, errors: [ErrorEntry(message: "Conflicts.", code: "CONFLICT_PENDING")])

    #expect(error.code?.rawValue == "CONFLICT_PENDING")
    #expect(error.code != .conflict)
    #expect(error.hasCode("CONFLICT_PENDING"))
    #expect(error.message == "409 CONFLICT_PENDING: Conflicts.")
  }

  @Test("a response with no envelope has no code, and its status still classifies it")
  func noEnvelope() {
    let error = APIError(status: 503)

    #expect(error.code == nil)
    #expect(error.kind == .server)
    #expect(error.message == "503")
    #expect(error.description == "503")
  }

  @Test("a Data API answer carrying errors under a success is an error the API answered")
  func dataError() {
    let error = APIError(
      status: 200,
      errors: [ErrorEntry(message: "Limit must be at most 50.", code: "VALIDATION_FAILED")]
    )

    #expect(error.kind == .data)
    #expect(error.kind.name == "DataError")
    #expect(error.status == 200)
    #expect(error.message == "200 VALIDATION_FAILED: Limit must be at most 50.")
    #expect(error.description == error.message)
  }

  @Test("every row names its class")
  func everyRowNamesItsClass() {
    let names: [APIError.Kind: String] = [
      .badRequest: "BadRequestError",
      .authentication: "AuthenticationError",
      .billing: "BillingError",
      .forbidden: "ForbiddenError",
      .notFound: "NotFoundError",
      .methodNotAllowed: "MethodNotAllowedError",
      .conflict: "ConflictError",
      .idempotencyKeyInUse: "IdempotencyKeyInUseError",
      .idempotentAnswerUnavailable: "IdempotentAnswerUnavailableError",
      .preconditionFailed: "PreconditionFailedError",
      .payloadTooLarge: "PayloadTooLargeError",
      .rateLimit: "RateLimitError",
      .server: "ServerError",
      .data: "DataError",
      .other: "ApiError",
    ]

    for (kind, name) in names {
      #expect(kind.name == name)
    }
    #expect(Set(names.values).count == names.count)
  }

  @Test("both kinds that answer an idempotency key are conflicts, and no other kind is")
  func conflictEdge() {
    let conflicts: [APIError.Kind] = [
      .conflict, .idempotencyKeyInUse, .idempotentAnswerUnavailable,
    ]
    let others: [APIError.Kind] = [
      .badRequest, .authentication, .billing, .forbidden, .notFound, .methodNotAllowed,
      .preconditionFailed, .payloadTooLarge, .rateLimit, .server, .data, .other,
    ]

    for kind in conflicts {
      #expect(kind.isConflict, "\(kind)")
    }
    for kind in others {
      #expect(!kind.isConflict, "\(kind)")
    }
  }
}
