/// PersistedQuerySupport is what a transport knows, for its lifetime, of whether the server
/// takes automatic persisted queries, and so what each operation's first attempt sends.
///
/// A declined protocol is remembered for the transport's lifetime, so it is not probed again. A
/// digest the server asked to have registered, and a digest that could not be computed, are
/// remembered by nothing: memoising a failure turns one bad moment into a permanent opt-out, so
/// the next operation computes its digest and probes again.
struct PersistedQuerySupport: Sendable, Hashable {
  /// isDeclined is true once the server answered that it does not implement persisted queries.
  private(set) var isDeclined = false

  /// firstAttempt returns what an operation's first attempt sends: its digest alone where the
  /// digest was computed and the protocol is not declined, and its document alone otherwise.
  /// `digest` is nil where the digest could not be computed, which sends the document in full
  /// rather than a substitute the server would refuse.
  func firstAttempt(digest: String?) -> PersistedQueryAttempt {
    guard let digest, !isDeclined else {
      return PersistedQueryAttempt(digest: nil, sendsDocument: true)
    }
    return PersistedQueryAttempt(digest: digest, sendsDocument: false)
  }

  /// read returns what the errors that answered `attempt` mean, and declines the protocol for
  /// the rest of the transport's lifetime where they say it is not implemented.
  mutating func read(_ errors: [ErrorEntry], answering attempt: PersistedQueryAttempt)
    -> PersistedQueryRefusal?
  {
    let refusal = PersistedQueryRefusal(errors: errors, answering: attempt)
    if refusal == .unsupported {
      isDeclined = true
    }
    return refusal
  }
}
