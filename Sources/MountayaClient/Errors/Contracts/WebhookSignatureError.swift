/// WebhookSignatureError is a webhook delivery `constructWebhookEvent` cannot trust: a
/// `Mountaya-Signature` header missing or malformed, a signature no `v1` of it matches, or a
/// timestamp outside the tolerance. `reason` says which.
///
/// `constructWebhookEvent` is the admin unit's, `import MountayaAdmin`, and this refusal is the
/// client's, carried by `MountayaError.webhookSignature`, so a receiver catches it as it catches
/// every failure of the SDK.
///
/// Answer such a delivery with a `400` and do nothing it asks. Mountaya repeats a delivery that
/// failed, so a refusal a wrong secret or a wrong clock caused costs an attempt and not the event:
/// once the secret or the clock is right, the next attempt verifies.
public struct WebhookSignatureError: Sendable, Hashable, CustomStringConvertible {
  /// Reason is why a delivery was refused, spelled as the contract spells it in `rawValue`.
  ///
  /// The set grows where the contract adds a reason, so a `switch` over it outside this module
  /// ends in `@unknown default`.
  @nonexhaustive
  public enum Reason: String, Sendable, Hashable {
    /// missingHeader is a request that carries no `Mountaya-Signature` header, or an empty one.
    case missingHeader = "missing-header"
    /// malformedHeader is a header that is not `t=<unix seconds>,v1=<signature>`: it holds no `t`
    /// or more than one, a `t` that is not whole seconds in digits alone, no `v1`, or an element
    /// that is no `key=value` pair.
    case malformedHeader = "malformed-header"
    /// signature is a header no `v1` of which is the signature of this body under this secret: the
    /// body was changed on the way, the secret is another endpoint's or one rotated away, or the
    /// delivery is not Mountaya's.
    case signature
    /// timestamp is a signature that verifies, made further from the receiver's clock than the
    /// tolerance, either way: a delivery replayed later, or a clock that is wrong.
    case timestamp
  }

  /// reason is why the delivery was refused.
  public let reason: Reason
  /// message says what was refused, and what to do about it, for the developer who reads the log.
  public let message: String

  /// Creates a refusal, such as a test's stand-in for one a delivery raised.
  public init(reason: Reason, message: String) {
    self.reason = reason
    self.message = message
  }

  /// description is the failure as a developer reads it in a log.
  public var description: String {
    message
  }
}
