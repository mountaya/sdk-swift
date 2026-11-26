import MountayaClient

/// Errors reads every error a call raises, as a caller's `catch` does.
enum Errors {
  /// read answers what a caller does with an error.
  static func read(_ error: any Error) -> String {
    guard isMountayaError(error), let error = error as? MountayaError else {
      return error is CancellationError ? "cancelled" : "foreign"
    }
    _ = (error.name, error.idempotencyKey, isAPIError(error))
    switch error {
    case .api(let apiError):
      _ = (apiError.status, apiError.errors.map(\.message), apiError.code, apiError.metadata)
      _ = (apiError.retryAfter, apiError.requestId, apiError.rateLimit, apiError.etag)
      _ = (apiError.idempotencyKey, apiError.cause, apiError.unavailableAnswer?.status)
      _ = apiError.message
      for entry in apiError.errors {
        for component in entry.path ?? [] {
          switch component {
          case .key(let key): _ = key
          case .index(let index): _ = index
          }
        }
      }
      if apiError.kind.isConflict {
        return "conflict"
      }
      switch apiError.kind {
      case .preconditionFailed: return "read it again"
      case .rateLimit: return "later"
      case .authentication, .forbidden: return "sign in"
      default: return apiError.kind.name
      }
    case .connection(let connection):
      _ = (connection.cause, ConnectionError(idempotencyKey: "key", cause: connection.cause))
      _ = ConfigurationError(message: "set up wrong", idempotencyKey: nil, cause: connection.cause)
      return connection.message
    case .configuration(let configuration):
      return configuration.message
    case .selection(let selection):
      return selection.path.joined(separator: ".")
    case .webhookSignature(let refusal):
      switch refusal.reason {
      case .missingHeader, .malformedHeader: return "no signature"
      case .signature: return "forged"
      case .timestamp: return "replayed"
      @unknown default: return refusal.message
      }
    @unknown default:
      return error.description
    }
  }
}
