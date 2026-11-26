import Testing

@testable import MountayaClient

@Suite("ErrorLadder")
struct ErrorLadderTests {
  @Test(
    "each 4xx a caller acts on has a row of its own",
    arguments: [
      (400, APIError.Kind.badRequest),
      (401, .authentication),
      (402, .billing),
      (403, .forbidden),
      (404, .notFound),
      (405, .methodNotAllowed),
      (409, .conflict),
      (412, .preconditionFailed),
      (413, .payloadTooLarge),
      (429, .rateLimit),
    ]
  )
  func fourHundreds(status: Int, kind: APIError.Kind) {
    #expect(ErrorLadder.kind(status: status, code: nil) == kind)
  }

  @Test("a 402 is one row whatever its code")
  func paymentRequiredIsOneRow() {
    for code: APIErrorCode in ["PAYMENT_REQUIRED", "SUBSCRIPTION_REQUIRED", "CARD_REQUIRED"] {
      #expect(ErrorLadder.kind(status: 402, code: code) == .billing)
    }
    #expect(ErrorLadder.kind(status: 402, code: nil) == .billing)
  }

  @Test("a 429 is one row whatever its code, a ceiling reached included")
  func tooManyRequestsIsOneRow() {
    for code: APIErrorCode in ["RATE_LIMITED", "LIMIT_REACHED"] {
      #expect(ErrorLadder.kind(status: 429, code: code) == .rateLimit)
    }
    #expect(ErrorLadder.kind(status: 429, code: nil) == .rateLimit)
  }

  @Test("a 409 answering an idempotency key is a row of its own, and any other code a conflict")
  func conflictsSplitOnTheKey() {
    #expect(ErrorLadder.kind(status: 409, code: "IDEMPOTENCY_KEY_IN_USE") == .idempotencyKeyInUse)
    #expect(
      ErrorLadder.kind(status: 409, code: "IDEMPOTENCY_ANSWER_UNAVAILABLE")
        == .idempotentAnswerUnavailable
    )
    #expect(ErrorLadder.kind(status: 409, code: "CONFLICT") == .conflict)
    #expect(ErrorLadder.kind(status: 409, code: "idempotency_key_in_use") == .conflict)
  }

  @Test("a code decides nothing outside a 409")
  func codeOnlySplitsA409() {
    #expect(ErrorLadder.kind(status: 402, code: "LIMIT_REACHED") == .billing)
    #expect(ErrorLadder.kind(status: 403, code: "LIMIT_REACHED") == .forbidden)
    #expect(ErrorLadder.kind(status: 400, code: "IDEMPOTENCY_KEY_IN_USE") == .badRequest)
    #expect(ErrorLadder.kind(status: 412, code: "CONFLICT") == .preconditionFailed)
  }

  @Test("a success status raised as an error is the Data API's, whatever its code")
  func successIsData() {
    for status in [200, 201, 299] {
      #expect(ErrorLadder.kind(status: status, code: "VALIDATION_FAILED") == .data)
      #expect(ErrorLadder.kind(status: status, code: nil) == .data)
    }
  }

  @Test("the whole 5xx range is one row, and its edges are not")
  func fiveHundreds() {
    for status in [500, 501, 502, 503, 504, 599] {
      #expect(ErrorLadder.kind(status: status, code: nil) == .server)
    }
    for status in [199, 300, 304, 418, 422, 499, 600] {
      #expect(ErrorLadder.kind(status: status, code: nil) == .other)
    }
  }
}
