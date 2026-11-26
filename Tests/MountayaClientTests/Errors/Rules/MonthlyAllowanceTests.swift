import Foundation
import Testing

@testable import MountayaClient

/// A `429` refused for a spent monthly allowance names when the allowance renews, never a wait to
/// sit out: nothing lifts it before the next billing period but a larger allowance.
@Suite("MonthlyAllowance")
struct MonthlyAllowanceTests {
  /// A quarter of a second past midnight on 2026-11-14, UTC, which the instant named truncates to
  /// its second.
  private static let now = Date(timeIntervalSince1970: 1_794_614_400.25)

  /// The policy an organization's allowance is counted under, a month long.
  private static let monthPolicy = "\"month\";q=300000;w=2678400"

  /// refusal is the error a `429` the API answers with these headers raises at `now`.
  private static func refusal(_ headers: [String: String], code: String = "TOO_MANY_REQUESTS")
    -> APIError
  {
    AnswerError.error(
      status: 429,
      headers: headers,
      envelope: ErrorEnvelope.read(
        Data(#"{"errors":[{"message":"Allowance used.","extensions":{"code":"\#(code)"}}]}"#.utf8)
      ),
      now: now,
      idempotencyKey: nil
    )
  }

  private static func state(_ policies: (name: String, remaining: Int64?)...) -> RateLimitState {
    RateLimitState(
      policies: policies.map { RateLimitPolicy(name: $0.name, quota: 1, remaining: $0.remaining) })
  }

  @Test("the allowance is spent where the month has nothing left and no other policy is spent")
  func isSpent() {
    #expect(MonthlyAllowance.isSpent(Self.state(("month", 0))))
    #expect(MonthlyAllowance.isSpent(Self.state(("month", 0), ("address", 4))))
    #expect(MonthlyAllowance.isSpent(Self.state(("month", 0), ("address", nil))))
    #expect(!MonthlyAllowance.isSpent(Self.state(("month", 0), ("minute", 0))))
    #expect(!MonthlyAllowance.isSpent(Self.state(("month", 41))))
    #expect(!MonthlyAllowance.isSpent(Self.state(("month", nil))))
    #expect(!MonthlyAllowance.isSpent(Self.state(("minute", 0))))
    #expect(!MonthlyAllowance.isSpent(Self.state()))
    #expect(!MonthlyAllowance.isSpent(nil))
  }

  @Test("the step names the seconds its wait names and the instant they end, to the second")
  func step() {
    #expect(
      MonthlyAllowance.step(retryAfter: .seconds(1_036_800), answeredAt: Self.now)
        == "The organization's monthly allowance on this API is spent: it renews when the next "
        + "billing period begins in 1036800 seconds (at 2026-11-26T00:00:00Z), so this call is "
        + "not repeated before then. A larger allowance is set in the organization's agreement "
        + "with Mountaya (https://mountaya.com/en/contact/).")
    #expect(
      MonthlyAllowance.step(retryAfter: .seconds(1), answeredAt: Self.now).contains(
        "begins in 1 second (at 2026-11-14T00:00:01Z), so"))
  }

  @Test("a wait it does not know names no seconds, and an instant it cannot place names none")
  func unknowns() {
    let bare =
      "The organization's monthly allowance on this API is spent: it renews when the next billing "
      + "period begins, so this call is not repeated before then."

    #expect(MonthlyAllowance.step(retryAfter: nil, answeredAt: Self.now).hasPrefix(bare))
    #expect(MonthlyAllowance.step(retryAfter: .zero, answeredAt: Self.now).hasPrefix(bare))
    #expect(
      MonthlyAllowance.step(retryAfter: .seconds(30), answeredAt: nil).contains(
        "begins in 30 seconds, so"))
    #expect(
      MonthlyAllowance.step(retryAfter: .seconds(9_999_999_999_999), answeredAt: Self.now)
        .contains("begins in 9999999999999 seconds, so this call is not repeated before then."))
  }

  @Test("a 429 refused for the spent allowance says when it renews, after the API's words")
  func message() {
    let spent = Self.refusal([
      "Retry-After": "1036800", "RateLimit": "\"month\";r=0;t=1036800",
      "RateLimit-Policy": Self.monthPolicy,
    ])

    #expect(spent.kind == .rateLimit)
    #expect(spent.retryAfter == .seconds(1_036_800))
    #expect(
      spent.description
        == "429 TOO_MANY_REQUESTS: Allowance used. The organization's monthly allowance on this "
        + "API is spent: it renews when the next billing period begins in 1036800 seconds (at "
        + "2026-11-26T00:00:00Z), so this call is not repeated before then. A larger allowance is "
        + "set in the organization's agreement with Mountaya (https://mountaya.com/en/contact/).")
    // In the last seconds of a period the wait is shorter than a minute's: the state, not the
    // wait, says it is the allowance.
    #expect(
      Self.refusal([
        "Retry-After": "1", "RateLimit": "\"month\";r=0;t=1", "RateLimit-Policy": Self.monthPolicy,
      ]).description.contains("begins in 1 second (at 2026-11-14T00:00:01Z), so"))
  }

  @Test("a per-minute refusal and a month with something left name a wait, and a ceiling its own")
  func otherRefusals() {
    let minute = Self.refusal([
      "Retry-After": "23", "RateLimit": "\"month\";r=0;t=1036800, \"minute\";r=0;t=23",
      "RateLimit-Policy": Self.monthPolicy + ", \"minute\";q=60;w=60",
    ])
    let left = Self.refusal([
      "Retry-After": "23", "RateLimit": "\"month\";r=41;t=1036800",
      "RateLimit-Policy": Self.monthPolicy,
    ])
    let ceiling = Self.refusal(
      ["RateLimit": "\"month\";r=0;t=1036800", "RateLimit-Policy": Self.monthPolicy],
      code: "LIMIT_REACHED"
    )

    #expect(
      minute.description
        == "429 TOO_MANY_REQUESTS: Allowance used. Wait 23 seconds before calling again.")
    #expect(
      left.description
        == "429 TOO_MANY_REQUESTS: Allowance used. Wait 23 seconds before calling again.")
    #expect(ceiling.description == "429 LIMIT_REACHED: Allowance used. \(NextStep.ceiling)")
  }

  @Test("an error a caller builds names the seconds of its wait, and no instant it cannot place")
  func callerBuilt() {
    let error = APIError(
      status: 429,
      errors: [ErrorEntry(message: "Allowance used", code: "TOO_MANY_REQUESTS")],
      retryAfter: .seconds(60),
      rateLimit: Self.state(("month", 0))
    )

    #expect(
      error.description.hasPrefix(
        "429 TOO_MANY_REQUESTS: Allowance used. The organization's monthly allowance on this API "
          + "is spent: it renews when the next billing period begins in 60 seconds, so"))
  }
}
