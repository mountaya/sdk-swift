import Foundation
import MountayaClient

/// constructWebhookEvent verifies a webhook delivery's signature and returns the event its body
/// holds, typed by its `type`.
///
/// Pass the body exactly as it arrived, before any JSON parser reads it: the signature covers those
/// bytes, and a body parsed and written out again is other bytes, which do not verify.
/// `signatureHeader` is the request's `Mountaya-Signature`, nil where it carries none, and
/// `secret` the signing secret of the endpoint the delivery was sent to, `whsk_` included.
///
/// The header is read first, then the signature, then the time, so a forged delivery is refused
/// for its signature whatever time it claims. A `v1` that matches is enough: while a rotated secret
/// overlaps its successor the header carries one for each, and either secret verifies it. The
/// signature is then held to `now`, the receiver's clock, the platform's where none is given: a
/// delivery signed further from it than `tolerance`, either way, is refused, and one signed exactly
/// that far is not.
///
/// The event's instants are `Date`s, as a method of the client answers them. An event this build
/// cannot type, of a type a newer contract added or whose payload its types do not read, is
/// returned too, as `unknown` holding the contract's envelope, so it is still acknowledged and
/// deduplicated by its `id`.
///
/// It throws `MountayaError.webhookSignature` for a delivery that cannot be trusted, its `reason`
/// saying why: answer it with a `400`. It throws `MountayaError.configuration` for a secret that
/// does not start with `whsk_`, which it never quotes, a tolerance below 0, a `now` that is no
/// finite instant, and a body that verifies and holds no webhook event envelope at all.
///
/// It is unavailable on every app platform, as the secret key is: a delivery is received by a
/// server, and the endpoint's secret never ships in an app. macOS and Linux keep it.
@available(
  iOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  tvOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  watchOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  visionOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  macCatalyst, unavailable,
  message: "A webhook signing secret belongs on a server, never in an app."
)
public func constructWebhookEvent(
  rawBody: Data,
  signatureHeader: String?,
  secret: String,
  tolerance: Duration = .seconds(300),
  now: Date? = nil
) throws(MountayaError) -> WebhookEvent {
  try verifiedWebhookEvent(
    rawBody: rawBody,
    signatureHeader: signatureHeader,
    secret: secret,
    tolerance: tolerance,
    now: now ?? SystemWallClock().now
  )
}

/// constructWebhookEvent verifies a webhook delivery whose body arrived as text, by the text's
/// UTF-8 bytes, which are the bytes Mountaya signed, and returns the event it holds, as
/// `constructWebhookEvent(rawBody:signatureHeader:secret:tolerance:now:)` does for bytes,
/// and is unavailable on every app platform as it is.
@available(
  iOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  tvOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  watchOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  visionOS, unavailable, message: "A webhook signing secret belongs on a server, never in an app."
)
@available(
  macCatalyst, unavailable,
  message: "A webhook signing secret belongs on a server, never in an app."
)
public func constructWebhookEvent(
  rawBody: String,
  signatureHeader: String?,
  secret: String,
  tolerance: Duration = .seconds(300),
  now: Date? = nil
) throws(MountayaError) -> WebhookEvent {
  try constructWebhookEvent(
    rawBody: Data(rawBody.utf8),
    signatureHeader: signatureHeader,
    secret: secret,
    tolerance: tolerance,
    now: now
  )
}

/// webhookSecretPrefix opens every endpoint's signing secret, and is keyed with the rest of it.
let webhookSecretPrefix = "whsk_"

/// verifiedWebhookEvent is `constructWebhookEvent` with the clock it judges a timestamp by stated.
func verifiedWebhookEvent(
  rawBody: Data,
  signatureHeader: String?,
  secret: String,
  tolerance: Duration,
  now: Date
) throws(MountayaError) -> WebhookEvent {
  guard secret.hasPrefix(webhookSecretPrefix) else {
    throw refusal(
      "The webhook signing secret does not start with `\(webhookSecretPrefix)`: pass the signing "
        + "secret of the endpoint the delivery was sent to, `\(webhookSecretPrefix)` included."
    )
  }
  let toleranceSeconds = seconds(tolerance)
  guard tolerance >= .zero else {
    throw refusal(
      "A tolerance of \(spelled(toleranceSeconds)) seconds is no number of seconds from 0: pass "
        + "one, or leave it out for 300."
    )
  }
  let clock = now.timeIntervalSince1970
  guard clock.isFinite else {
    throw refusal("The receiver's clock is no finite instant: pass one, or leave it out.")
  }

  guard !SignatureHeader.isMissing(signatureHeader), let signatureHeader else {
    throw MountayaError.webhookSignature(
      WebhookSignatureError(
        reason: .missingHeader,
        message: "The request carries no `Mountaya-Signature` header: pass the header the "
          + "request carries, and answer a request without one with a 400."
      )
    )
  }
  guard let header = SignatureHeader.parse(signatureHeader) else {
    throw MountayaError.webhookSignature(
      WebhookSignatureError(
        reason: .malformedHeader,
        message: "The `Mountaya-Signature` header is not `t=<unix seconds>,v1=<signature>`: "
          + "pass the header exactly as the request carries it."
      )
    )
  }
  let expected = WebhookSignature.expected(stated: header.stated, body: rawBody, secret: secret)
  guard WebhookSignature.verifies(header.signatures, expected: expected) else {
    throw MountayaError.webhookSignature(
      WebhookSignatureError(
        reason: .signature,
        message: "No `v1` of the `Mountaya-Signature` header is the signature of this body under "
          + "this secret: pass the body exactly as it arrived, before any JSON parser reads it, "
          + "and the secret of the endpoint the delivery was sent to."
      )
    )
  }
  let skew = abs(clock - Double(header.timestamp))
  guard skew <= toleranceSeconds else {
    throw MountayaError.webhookSignature(
      WebhookSignatureError(
        reason: .timestamp,
        message: "The delivery was signed at \(signedAt(header.timestamp)), "
          + "\(spelled(skew.rounded())) seconds from this clock, past the tolerance of "
          + "\(spelled(toleranceSeconds)) seconds: a delivery replayed later is refused this way, "
          + "and where the clock is wrong, set it right."
      )
    )
  }

  // The body verified, so it is the event Mountaya signed, read as the contract declares it, or
  // as its envelope where this build cannot type it.
  do {
    return try JSONDecoder().decode(WebhookEvent.self, from: rawBody)
  } catch {
    throw MountayaError.configuration(
      ConfigurationError(
        message: "The body verified, and holds no webhook event: not even the envelope every "
          + "event is delivered in reads.",
        cause: error
      )
    )
  }
}

/// refusal is the configuration error a call set up wrong raises.
private func refusal(_ message: String) -> MountayaError {
  .configuration(ConfigurationError(message: message))
}

/// seconds is a span as a count of seconds, the fraction its attoseconds make included.
private func seconds(_ span: Duration) -> Double {
  let (seconds, attoseconds) = span.components
  return Double(seconds) + Double(attoseconds) / 1e18
}

/// spelled writes a count of seconds as a whole number where it is one, and as Swift writes a
/// `Double` otherwise.
private func spelled(_ seconds: Double) -> String {
  guard seconds.rounded() == seconds, abs(seconds) < 1e15 else { return "\(seconds)" }
  return String(Int64(seconds))
}

/// signedAt writes the instant a `t` names, as the contract writes an instant, or the `t` itself
/// where the instant falls past the year 9999.
private func signedAt(_ timestamp: Int64) -> String {
  guard timestamp <= 253_402_300_799 else { return "t=\(timestamp)" }
  return Timestamp.string(from: Date(timeIntervalSince1970: Double(timestamp)))
}
