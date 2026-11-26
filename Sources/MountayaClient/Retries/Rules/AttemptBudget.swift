/// AttemptBudget decides how long one attempt may take before it is given up as a request that
/// never arrived.
///
/// The budget is a deadline the transport holds itself, from the moment the attempt starts to
/// the last byte of its answer, the wait for a first session token included.
enum AttemptBudget {
  /// clientDefault is a client's budget where it states none.
  static let clientDefault: Duration = .seconds(30)
  /// margin is what the operation's own budget is widened by, so the API's own 504 arrives
  /// before the client gives up on it and a write the API is still running is not abandoned
  /// for a repeat that would meet it in flight.
  static let margin: Duration = .seconds(5)

  /// budget returns an attempt's budget: the call's own where it names one, so a caller can
  /// wait less or more than the API would, and otherwise the larger of the client's and the
  /// operation's own budget plus the margin. An operation that declares none, as an event
  /// stream does, takes the client's.
  static func budget(call: Duration?, client: Duration, operation: Duration?) -> Duration {
    if let call {
      return call
    }
    guard let operation else { return client }
    return max(client, operation + margin)
  }

  /// check refuses a budget of zero or less, which no attempt could fit in.
  static func check(_ budget: Duration, as part: String) throws(MountayaError) {
    guard budget > .zero else {
      throw .configuration(
        ConfigurationError(
          message: "\(part) is a time budget, and one of zero or less fits no attempt.")
      )
    }
  }
}
