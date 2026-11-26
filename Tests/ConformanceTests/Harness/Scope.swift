import GateSupport

/// Scope is the table of capabilities this SDK does not implement, each by the sentence of
/// SPEC.md section 11 that says so.
///
/// A scoped capability is reported, never skipped: a skip is indistinguishable from a runner
/// nobody wrote.
enum Scope {
  /// Rule scopes a whole layer, or one capability by its id.
  struct Rule: Sendable, Hashable {
    enum Subject: Sendable, Hashable {
      case layer(Registry.Layer)
      case id(String)
    }

    let subject: Subject
    /// bullet is the bold opening of the section 11 bullet that makes the divergence
    /// deliberate. A test reads SPEC.md and fails when the bullet is gone.
    let bullet: String
  }

  static let rules: [Rule] = [
    Rule(subject: .layer(.studio), bullet: "No studio layer."),
    Rule(
      subject: .id("transport.browser.secret-key"),
      bullet: "No browser refusal for the secret key."
    ),
  ]

  /// rule returns the rule that scopes a capability, or nil when the SDK owes it a runner.
  static func rule(for capability: Registry.Capability, in rules: [Rule] = Scope.rules) -> Rule? {
    rules.first { rule in
      switch rule.subject {
      case .layer(let layer): return capability.layer == layer
      case .id(let id): return capability.id == id
      }
    }
  }
}
