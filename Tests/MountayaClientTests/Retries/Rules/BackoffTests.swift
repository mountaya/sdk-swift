import Testing

@testable import MountayaClient

@Suite("Backoff")
struct BackoffTests {
  private static func delay(
    _ attempt: Int,
    draw: Double,
    retryAfter: Duration? = nil,
    waited: Duration = .zero,
    policy: RetryPolicy = .standard
  ) -> Duration? {
    Backoff.delay(
      after: attempt,
      policy: policy,
      draw: draw,
      retryAfter: retryAfter,
      waited: waited
    )
  }

  @Test("the ceiling doubles with each attempt up to the policy's maximum")
  func ceilingDoubles() {
    #expect(Self.delay(0, draw: 1) == .milliseconds(500))
    #expect(Self.delay(1, draw: 1) == .milliseconds(1000))
    #expect(Self.delay(5, draw: 1) == .milliseconds(16_000))
    #expect(Self.delay(6, draw: 1) == .seconds(30))
    #expect(Self.delay(7, draw: 1) == .seconds(30))
  }

  @Test("the wait is the draw's share of the ceiling, so a zero draw waits nothing")
  func drawScales() {
    #expect(Self.delay(3, draw: 0) == .zero)
    #expect(Self.delay(3, draw: 0.5) == .milliseconds(2000))
    #expect(Self.delay(3, draw: 0.25) == .milliseconds(1000))
  }

  @Test("an attempt count past any power the ceiling could hold still lands on the ceiling")
  func hugeAttemptsDoNotOverflow() {
    #expect(Self.delay(64, draw: 1) == .seconds(30))
    #expect(Self.delay(2000, draw: 1) == .seconds(30))
  }

  @Test("a Retry-After replaces the schedule with its seconds and up to one more second")
  func retryAfterWins() {
    #expect(Self.delay(0, draw: 0, retryAfter: .seconds(42)) == .seconds(42))
    #expect(Self.delay(0, draw: 1, retryAfter: .seconds(42)) == .seconds(43))
    #expect(Self.delay(0, draw: 0.5, retryAfter: .seconds(42)) == .milliseconds(42_500))
    #expect(Self.delay(4, draw: 0.25, retryAfter: .seconds(1)) == .milliseconds(1250))
    #expect(Self.delay(4, draw: 0, retryAfter: .zero) == .zero)
  }

  @Test("a wait is taken only where it fits what the waits before it left of the budget")
  func waitBudget() {
    #expect(Self.delay(0, draw: 0, retryAfter: .seconds(60)) == .seconds(60))
    #expect(Self.delay(0, draw: 0.5, retryAfter: .seconds(60)) == nil)
    #expect(Self.delay(0, draw: 0, retryAfter: .seconds(61)) == nil)
    #expect(Self.delay(0, draw: 1, retryAfter: .seconds(57), waited: .milliseconds(3500)) == nil)
    #expect(Self.delay(0, draw: 1, retryAfter: .seconds(57), waited: .seconds(2)) == .seconds(58))
    #expect(Self.delay(6, draw: 1, waited: .milliseconds(31_500)) == nil)
    #expect(Self.delay(5, draw: 1, waited: .milliseconds(15_500)) == .seconds(16))
  }

  @Test("a wait shorter than its minimum is lengthened to it before it is held to the budget")
  func minimum() throws {
    let policy = try RetryPolicy(
      maxRetries: 0, baseDelay: .zero, maxDelay: .zero, waitBudget: .seconds(2))
    let least = Backoff.keyInUseMinimum

    #expect(
      Backoff.delay(
        after: 0, policy: policy, draw: 0, retryAfter: .zero, waited: .zero, minimum: least)
        == .seconds(1))
    #expect(
      Backoff.delay(
        after: 0, policy: policy, draw: 0.5, retryAfter: .seconds(1), waited: .zero,
        minimum: least) == .milliseconds(1500))
    #expect(
      Backoff.delay(
        after: 0, policy: policy, draw: 0, retryAfter: nil, waited: .milliseconds(1500),
        minimum: least) == nil)
    #expect(
      Backoff.delay(
        after: 0, policy: policy, draw: 0, retryAfter: nil, waited: .seconds(1), minimum: least)
        == .seconds(1))
  }

  @Test("a wider budget waits out a longer wait, and a budget of nothing waits none")
  func otherBudgets() throws {
    let wide = try RetryPolicy(waitBudget: .seconds(300))
    let none = try RetryPolicy(waitBudget: .zero)

    #expect(Self.delay(0, draw: 0, retryAfter: .seconds(120), policy: wide) == .seconds(120))
    #expect(Self.delay(0, draw: 0, retryAfter: .seconds(2_147_484)) == nil)
    #expect(Self.delay(0, draw: 0, policy: none) == .zero)
    #expect(Self.delay(0, draw: 0.1, policy: none) == nil)
  }
}
