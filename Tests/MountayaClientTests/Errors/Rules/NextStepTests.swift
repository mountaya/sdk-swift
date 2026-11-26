import Foundation
import Testing

@testable import MountayaClient

/// Every step an error's description ends on, word for word, each for the status, the code and the
/// declaration that names it, and nothing for a status that names none.
@Suite("NextStep")
struct NextStepTests {
  private static let member = NextStep.Declaration(OperationFacts.patchItinerary.credentials)
  /// `postSession`, the one operation a secret key authenticates, is the admin unit's, whose
  /// printed facts state this declaration (`MountayaAdminTests`).
  private static let mints = NextStep.Declaration(CredentialDeclaration(requiresSecretKey: true))

  /// step is the step a failure of `status` names, with no rate-limit state and no arrival.
  private static func step(
    _ status: Int,
    code: APIErrorCode? = nil,
    retryAfter: Duration? = nil,
    declaration: NextStep.Declaration = .none
  ) -> String? {
    NextStep.step(
      status: status, code: code, retryAfter: retryAfter, rateLimit: nil,
      declaration: declaration, answeredAt: nil)
  }

  @Test("an operation's credential facts say whether it acts as a member and whether it mints")
  func declarations() {
    #expect(Self.member == NextStep.Declaration(actsAsMember: true, requiresSecretKey: false))
    #expect(Self.mints == NextStep.Declaration(actsAsMember: false, requiresSecretKey: true))
    #expect(NextStep.Declaration(OperationFacts.getItinerary.credentials) == .none)
    #expect(
      NextStep.Declaration(CredentialDeclaration(actingUser: .optional, requiresSession: true))
        == .none)
  }

  @Test("a 401 names the credential to check, the member's token, or the secret key that mints")
  func authentication() {
    #expect(
      Self.step(401, code: "UNAUTHORIZED")
        == "Check the credential this client sends: a key that is unknown, rotated or disabled, "
        + "and a session token that has expired, are refused.")
    #expect(
      Self.step(401, code: "UNAUTHORIZED", declaration: Self.member)
        == "Check the credential this client sends: a key that is unknown, rotated or disabled, "
        + "and a session token that has expired, are refused. This call acts as the user its "
        + "session token was minted for, so mint the token with postSession's user_id set to "
        + "that user.")
    #expect(
      Self.step(401, code: "UNAUTHORIZED", declaration: Self.mints)
        == "Check the secret key this client sends: one that is unknown, revoked or malformed, or "
        + "one of a canceled organization, is refused.")
  }

  @Test("a 402 names where each of its remedies is taken, whatever its code, and offers nothing")
  func billing() {
    for code in ["PAYMENT_REQUIRED", nil] as [APIErrorCode?] {
      let step = Self.step(402, code: code)

      #expect(
        step
          == "The API's message says which applies: a product of the organization's agreement is "
          + "changed with Mountaya (https://mountaya.com/en/contact/), and a missing payment method "
          + "is added, or an invoice still owed paid, in the organization's billing settings.")
      #expect(step?.contains("ceiling") == false)
    }
  }

  @Test("a 403 names the scope, the member's role, or the publishable key and user it mints for")
  func forbidden() {
    let forbidden =
      "Check that the key carries the scope this call needs, that the resource belongs to the "
      + "key's organization, and that the page calling is one the organization allows."

    #expect(Self.step(403, code: "FORBIDDEN") == forbidden)
    #expect(
      Self.step(403, code: "FORBIDDEN", declaration: Self.member)
        == forbidden + " This call acts as the user its session token names (postSession's "
        + "user_id), who must be a member of the key's organization holding the role the call "
        + "asks.")
    #expect(
      Self.step(403, code: "FORBIDDEN", declaration: Self.mints)
        == "Check that the publishable key in the body is one this secret key's organization "
        + "issued, and that user_id names a member of that organization or a user holding an "
        + "invitation to it.")
    // A product not held is a 402 and a ceiling a 429: a 403 sends its reader to neither.
    #expect(Self.step(403)?.contains("agreement") == false)
    #expect(Self.step(403)?.contains("payment method") == false)
    #expect(Self.step(403)?.contains("user_id") == false)
  }

  @Test("of the 409s, the two that answer a key name what to do, and every other none")
  func conflicts() {
    #expect(
      Self.step(409, code: "IDEMPOTENCY_ANSWER_UNAVAILABLE")
        == "The write was made, and its answer cannot be given again: read the resource again "
        + "rather than sending the write once more.")
    #expect(
      Self.step(409, code: "IDEMPOTENCY_KEY_IN_USE")
        == "The first request with this Idempotency-Key is still running: send the same call "
        + "again with the error's idempotencyKey, never a new key, which would make the write "
        + "twice.")
    #expect(Self.step(409, code: "CONFLICT") == nil)
    #expect(Self.step(409) == nil)
  }

  @Test("a 412 says the resource changed since the tag the write names")
  func precondition() {
    #expect(
      Self.step(412, code: "PRECONDITION_FAILED")
        == "The resource changed since the etag this write names was read: read it again, and "
        + "decide what the write should be now.")
  }

  @Test("a 429 names the wait, one second in the singular, and a wait of none without a number")
  func waits() {
    #expect(Self.step(429, code: "TOO_MANY_REQUESTS") == "Wait before calling again.")
    #expect(Self.step(429, retryAfter: .zero) == "Wait before calling again.")
    #expect(Self.step(429, retryAfter: .seconds(1)) == "Wait 1 second before calling again.")
    #expect(Self.step(429, retryAfter: .seconds(120)) == "Wait 120 seconds before calling again.")
    #expect(
      Self.step(429, retryAfter: .seconds(30), declaration: Self.mints)
        == "Wait 30 seconds before calling again. Minting is limited per secret key, per client "
        + "IP address and secret key whose requests keep failing, and per user_id it refuses, so "
        + "check the publishable key and the user_id before asking again.")
  }

  @Test("a ceiling names its remedies, never a wait, before a spent allowance or a mint's limit")
  func ceiling() {
    let ceiling =
      "No wait lifts a ceiling, so this call is not repeated: free a place in what the error's "
      + "metadata names, or change the organization's agreement with Mountaya "
      + "(https://mountaya.com/en/contact/) where it sets that ceiling."
    let spent = RateLimitState(policies: [RateLimitPolicy(name: "month", quota: 1, remaining: 0)])

    #expect(Self.step(429, code: "LIMIT_REACHED") == ceiling)
    #expect(Self.step(429, code: "LIMIT_REACHED", declaration: Self.mints) == ceiling)
    #expect(
      NextStep.step(
        status: 429, code: "LIMIT_REACHED", retryAfter: .seconds(5), rateLimit: spent,
        declaration: .none, answeredAt: nil) == ceiling)
  }

  @Test("a spent allowance names when it renews, before the wait and a mint's limit")
  func allowance() {
    let spent = RateLimitState(policies: [RateLimitPolicy(name: "month", quota: 1, remaining: 0)])

    #expect(
      NextStep.step(
        status: 429, code: "TOO_MANY_REQUESTS", retryAfter: .seconds(60), rateLimit: spent,
        declaration: Self.mints, answeredAt: nil)
        == MonthlyAllowance.step(retryAfter: .seconds(60), answeredAt: nil))
  }

  @Test(
    "every other status names nothing beyond the API's own words",
    arguments: [
      200, 400, 404, 405, 413, 418, 500, 502, 503, 504,
    ])
  func nothing(status: Int) {
    #expect(
      Self.step(status, code: "ANY", retryAfter: .seconds(3), declaration: Self.member) == nil)
  }

  @Test("the description ends on the step, a period added where the API's words end in none")
  func description() {
    #expect(
      APIError(status: 403, errors: [ErrorEntry(message: "Access is forbidden", code: "FORBIDDEN")])
        .description
        == "403 FORBIDDEN: Access is forbidden. Check that the key carries the scope this call "
        + "needs, that the resource belongs to the key's organization, and that the page calling "
        + "is one the organization allows.")
    #expect(
      APIError(status: 412, errors: [ErrorEntry(message: "Stale!", code: "PRECONDITION_FAILED")])
        .description.hasPrefix("412 PRECONDITION_FAILED: Stale! The resource changed"))
    #expect(APIError(status: 412).description.hasPrefix("412. The resource changed"))
    #expect(
      APIError(
        status: 404, errors: [ErrorEntry(message: "Itinerary not found.", code: "NOT_FOUND")]
      )
      .description == "404 NOT_FOUND: Itinerary not found.")
    #expect(
      MountayaError.api(
        APIError(status: 429, errors: [ErrorEntry(message: "No seat left.", code: "LIMIT_REACHED")])
      ).description
        == "RateLimitError: 429 LIMIT_REACHED: No seat left. No wait lifts a ceiling, so this call "
        + "is not repeated: free a place in what the error's metadata names, or change the "
        + "organization's agreement with Mountaya (https://mountaya.com/en/contact/) where it "
        + "sets that ceiling.")
  }

  @Test("an answer's error names the step its operation's declaration sharpens")
  func answered() {
    let refused = ErrorEnvelope.read(
      Data(#"{"errors":[{"message":"refused","extensions":{"code":"UNAUTHORIZED"}}]}"#.utf8))
    let error = AnswerError.error(
      status: 401, headers: [:], envelope: refused, now: Date(timeIntervalSince1970: 0),
      idempotencyKey: nil, declaration: Self.member)

    #expect(error.description.hasPrefix("401 UNAUTHORIZED: refused. Check the credential"))
    #expect(
      error.description.hasSuffix("mint the token with postSession's user_id set to that user."))
    #expect(error.carrying(idempotencyKey: "k").description == error.description)
  }

  @Test("a call's error names its operation's step, through the client")
  func throughTheClient() async throws {
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"),
      exchange: Refusing(status: 403, code: "FORBIDDEN"))

    do {
      _ = try await client.studio.itineraries.patchItinerary(
        itinerary_id: "it", body: RestSchema.ItineraryUpdateParams())
      Issue.record("a refused call answered")
    } catch let error as MountayaError {
      #expect(
        error.description.hasSuffix(
          "This call acts as the user its session token names (postSession's user_id), who must "
            + "be a member of the key's organization holding the role the call asks."))
    }
  }

  /// Refusing answers every attempt with one refusal.
  private struct Refusing: HTTPExchange {
    let status: Int
    let code: String

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: status,
        headers: ["Content-Type": "application/json"],
        body: ExchangeBody(
          Data(#"{"errors":[{"message":"refused","extensions":{"code":"\#(code)"}}]}"#.utf8)))
    }
  }
}
