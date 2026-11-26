import Testing

@testable import MountayaClient

@Suite("RetryEligibility")
struct RetryEligibilityTests {
  private static func allows(
    _ status: Int?,
    code: APIErrorCode? = nil,
    idempotent: Bool = false,
    keyed: Bool = false,
    attempt: Int = 0,
    policy: RetryPolicy = .standard
  ) -> Bool {
    RetryEligibility.allowsRetry(
      after: attempt,
      status: status,
      code: code,
      idempotent: idempotent,
      keyed: keyed,
      policy: policy
    )
  }

  @Test("a 429 is repeated whatever the operation declares and whatever the request carried")
  func rateLimitAlways() {
    #expect(Self.allows(429, idempotent: true))
    #expect(Self.allows(429))
    #expect(Self.allows(429, keyed: true))
  }

  @Test("a ceiling's 429 is never repeated, whatever the operation declares or the attempts left")
  func ceilingNever() throws {
    let generous = try RetryPolicy(maxRetries: 9)

    #expect(!Self.allows(429, code: "LIMIT_REACHED"))
    #expect(!Self.allows(429, code: "LIMIT_REACHED", idempotent: true))
    #expect(!Self.allows(429, code: "LIMIT_REACHED", keyed: true))
    #expect(
      !Self.allows(429, code: "LIMIT_REACHED", idempotent: true, keyed: true, policy: generous))
    #expect(Self.allows(429, code: "RATE_LIMITED"))
    #expect(Self.allows(429, code: "limit_reached"))
    #expect(Self.allows(503, code: "LIMIT_REACHED", idempotent: true))
  }

  @Test("a gateway failure or a lost connection is repeated where it is idempotent or keyed")
  func idempotentOrKeyed() {
    for status in [502, 503, 504, nil] {
      #expect(Self.allows(status, idempotent: true))
      #expect(Self.allows(status, keyed: true))
      #expect(Self.allows(status, idempotent: true, keyed: true))
      #expect(!Self.allows(status))
    }
  }

  @Test("a 409 whose key is still in use is repeated where the request carried a key")
  func keyInUse() {
    #expect(Self.allows(409, code: "IDEMPOTENCY_KEY_IN_USE", keyed: true))
    #expect(!Self.allows(409, code: "IDEMPOTENCY_KEY_IN_USE", idempotent: true))
    #expect(!Self.allows(409, code: "CONFLICT", keyed: true))
    #expect(!Self.allows(409, code: "IDEMPOTENCY_ANSWER_UNAVAILABLE", keyed: true))
    #expect(!Self.allows(409, keyed: true))
  }

  @Test("a key in use is counted against no ceiling of attempts")
  func keyInUsePastTheCeiling() throws {
    let off = try RetryPolicy(maxRetries: 0)

    #expect(Self.allows(409, code: "IDEMPOTENCY_KEY_IN_USE", keyed: true, attempt: 2))
    #expect(Self.allows(409, code: "IDEMPOTENCY_KEY_IN_USE", keyed: true, attempt: 40))
    #expect(Self.allows(409, code: "IDEMPOTENCY_KEY_IN_USE", keyed: true, policy: off))
  }

  @Test("every other status is answered the same way twice, so it is not repeated")
  func othersNever() {
    for status in [400, 401, 402, 403, 404, 405, 412, 413, 418, 500, 501, 505] {
      #expect(!Self.allows(status, idempotent: true))
      #expect(!Self.allows(status, keyed: true))
    }
  }

  @Test("the policy's count of retries is the last word, and zero turns retrying off")
  func exhausted() throws {
    #expect(Self.allows(429, attempt: 1))
    #expect(!Self.allows(429, attempt: 2))
    #expect(!Self.allows(503, keyed: true, attempt: 2))

    let off = try RetryPolicy(maxRetries: 0)
    #expect(!Self.allows(429, idempotent: true, policy: off))
    #expect(!Self.allows(nil, idempotent: true, policy: off))
  }
}
