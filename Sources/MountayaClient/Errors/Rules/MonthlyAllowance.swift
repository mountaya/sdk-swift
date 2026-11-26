import Foundation

/// MonthlyAllowance is what a `429` refused for an organization's spent monthly allowance says to
/// its caller: nothing lifts it before the organization's next billing period begins but a larger
/// allowance in its agreement, so the error names when that is, in the seconds its `Retry-After`
/// names and the instant in UTC they end, rather than a wait a caller would sit out.
enum MonthlyAllowance {
  /// The policy the monthly allowance is counted under, as `RateLimit-Policy` names it.
  static let policy = "month"

  /// The latest instant the step names, the last second of the year 9999: a wait that ends past
  /// it is named in seconds alone.
  private static let latestInstant: TimeInterval = 253_402_300_799

  /// isSpent returns whether a `429`'s rate-limit state says it was refused for a spent monthly
  /// allowance: its `month` policy has nothing left, and no other policy it lists is spent.
  ///
  /// A refusal for the allowance is weighed before every per-minute bound, so it lists none of
  /// them spent; a per-minute refusal while the allowance is spent to its last unit lists that
  /// bound spent too, and stays a wait.
  static func isSpent(_ state: RateLimitState?) -> Bool {
    let policies = state?.policies ?? []
    return policies.contains { $0.name == policy && $0.remaining == 0 }
      && policies.allSatisfy { $0.name == policy || $0.remaining != 0 }
  }

  /// step is the sentence that names when the allowance renews: in the whole seconds `retryAfter`
  /// names, counted from `answeredAt`, the instant the answer arrived, and the instant in UTC they
  /// end, each left out where it is not known, and the seconds where they are none.
  static func step(retryAfter: Duration?, answeredAt: Date?) -> String {
    var when = ""
    if let retryAfter, retryAfter > .zero {
      let seconds = retryAfter.components.seconds
      when = " in \(NextStep.seconds(seconds))"
      if let answeredAt {
        let end = answeredAt.timeIntervalSince1970 + Double(seconds)
        if end.isFinite, end <= latestInstant {
          when += " (at \(Timestamp.secondString(from: Date(timeIntervalSince1970: end))))"
        }
      }
    }
    return "The organization's monthly allowance on this API is spent: it renews when the next "
      + "billing period begins\(when), so this call is not repeated before then. A larger "
      + "allowance is set in the organization's agreement with Mountaya "
      + "(https://mountaya.com/en/contact/)."
  }
}
