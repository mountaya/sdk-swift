/// RateLimitHeaders reads the limits an answer was counted against from its `RateLimit-Policy`
/// and `RateLimit` fields, as the IETF's RateLimit header fields for HTTP state them.
enum RateLimitHeaders {
  /// state returns one policy per String member of `policy`, in its order, each with the
  /// remaining figure and reset of the member of `remaining` of the same name, or nil where no
  /// policy is left.
  ///
  /// A member that is not a String, or whose `q` is not a whole number of zero or more, is left
  /// out, and so is a member of `remaining` naming no policy, since its quota is unknown. A
  /// parameter this reader does not know is ignored, and a figure that is not a whole number of
  /// zero or more is one not stated. A field that does not parse is ignored whole: no policy
  /// where it is `policy`, and no figure where it is `remaining`.
  static func state(policy: String?, remaining: String?) -> RateLimitState? {
    guard let policy, let members = StructuredFieldList.parse(policy) else { return nil }
    let figures = remaining.flatMap(StructuredFieldList.parse) ?? []
    var policies: [RateLimitPolicy] = []
    for member in members {
      guard case .item(.string(let name), let parameters) = member,
        let quota = wholeNumber(parameters, named: "q")
      else {
        continue
      }
      let state = figures.lazy.compactMap { figure -> [StructuredFieldList.Parameter]? in
        guard case .item(.string(name), let parameters) = figure else { return nil }
        return parameters
      }.first
      policies.append(
        RateLimitPolicy(
          name: name,
          quota: quota,
          window: wholeNumber(parameters, named: "w").map { .seconds($0) },
          remaining: state.flatMap { wholeNumber($0, named: "r") },
          reset: state.flatMap { wholeNumber($0, named: "t") }.map { .seconds($0) }
        )
      )
    }
    return policies.isEmpty ? nil : RateLimitState(policies: policies)
  }

  /// wholeNumber returns the parameter named `key` where it is an integer of zero or more.
  private static func wholeNumber(_ parameters: [StructuredFieldList.Parameter], named key: String)
    -> Int64?
  {
    guard case .integer(let value)? = parameters.first(where: { $0.key == key })?.value,
      value >= 0
    else {
      return nil
    }
    return value
  }
}
