/// MountayaError is every failure the client reports, one case per class of the contract's error
/// ladder.
///
/// Catching `.api` catches every error the API answered, a Data API answer carrying errors under
/// a success included, which separates a failure of the API from a bug in the calling program.
/// A cancelled call is never one of these: it throws `CancellationError`, which is how
/// structured concurrency reads a cancellation, and a cancellation wrapped in something else
/// reads as a failure.
///
/// The ladder grows when the contract adds a class, so a `switch` over it outside this module
/// ends in `@unknown default`.
@nonexhaustive
public enum MountayaError: NamedError, Sendable, CustomStringConvertible {
  /// api is an error the API answered, whatever its status.
  case api(APIError)
  /// connection is a request that never arrived.
  case connection(ConnectionError)
  /// configuration is a client or a call set up wrong, refused before any request left the
  /// process.
  case configuration(ConfigurationError)
  /// selection is a field selection naming a field outside the operation's field tree.
  case selection(SelectionError)
  /// webhookSignature is a webhook delivery `constructWebhookEvent`, the admin unit's, cannot
  /// trust, refused before its body is read.
  case webhookSignature(WebhookSignatureError)

  /// name is the contract's name for the error's class, such as `PreconditionFailedError`.
  ///
  /// It is what a conformance fixture names, and what a log or a report can carry. A Swift
  /// caller pattern-matches on the case and on `APIError.kind` instead.
  public var name: String {
    switch self {
    case .api(let error): error.kind.name
    case .connection: "ConnectionError"
    case .configuration: "ConfigurationError"
    case .selection: "SelectionError"
    case .webhookSignature: "WebhookSignatureError"
    }
  }

  /// idempotencyKey is the `Idempotency-Key` the call that raised the error sent, the caller's
  /// as given or the one the client drew, whatever the error, or nil where it sent none.
  ///
  /// An answer that never came, a 5xx and a refusal do not say the write was not made, so a
  /// caller sends the same call again with this key, never a new one: a new key is a second
  /// write, made beside the first.
  public var idempotencyKey: String? {
    switch self {
    case .api(let error): error.idempotencyKey
    case .connection(let error): error.idempotencyKey
    case .configuration(let error): error.idempotencyKey
    case .selection, .webhookSignature: nil
    }
  }

  /// carrying returns the same error carrying the key its call sent, or itself where there is
  /// none.
  func carrying(idempotencyKey key: String?) -> MountayaError {
    guard let key else { return self }
    switch self {
    case .api(let error):
      return .api(error.carrying(idempotencyKey: key))
    case .connection(let error):
      return .connection(
        ConnectionError(idempotencyKey: key, cause: error.cause))
    case .configuration(let error):
      return .configuration(
        ConfigurationError(
          message: error.message,
          idempotencyKey: key,
          cause: error.cause
        )
      )
    case .selection, .webhookSignature:
      return self
    }
  }

  /// apiNames is the contract's name of every class an answer of the API raises.
  static let apiNames: Set<String> = Set(APIError.Kind.allNames)

  /// familyNames is the contract's name of every class of the family, the refusal of a webhook
  /// delivery included, which no request is behind.
  static let familyNames: Set<String> = apiNames.union([
    "ConnectionError", "ConfigurationError", "SelectionError", "WebhookSignatureError",
  ])

  /// description is the failure as a developer reads it in a log.
  public var description: String {
    switch self {
    case .api(let error): "\(name): \(error)"
    case .connection(let error): "\(name): \(error)"
    case .configuration(let error): "\(name): \(error)"
    case .selection(let error): "\(name): \(error)"
    case .webhookSignature(let error): "\(name): \(error)"
    }
  }
}

/// isMountayaError returns whether a value is an error of the family, read by the name its type
/// declares as data rather than by its type: a `NamedError` of any type, the client's own or one
/// another copy of the SDK or code that never linked it built, is recognised by the name it
/// declares, and a value that declares no name of the family is none of its errors, whatever
/// status it carries.
public func isMountayaError(_ value: (any Error)?) -> Bool {
  guard let error = value as? any NamedError else { return false }
  return MountayaError.familyNames.contains(error.name)
}

/// isAPIError returns whether a value is an error the API answered, a Data API answer carrying
/// errors under a success included, read by the name its type declares as data, whatever type
/// declares it.
public func isAPIError(_ value: (any Error)?) -> Bool {
  guard let error = value as? any NamedError else { return false }
  return MountayaError.apiNames.contains(error.name)
}
