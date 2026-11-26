/// ErrorLadder places an answer the API gave on the contract's error ladder.
enum ErrorLadder {
  /// kind returns the row a status falls on, reading the first entry's code only where the
  /// status is a 409.
  ///
  /// A 402 is one row whatever its code, the Data API's bare `PAYMENT_REQUIRED` included, and so
  /// is a 429, a ceiling's coded `LIMIT_REACHED` included. A success status that is an error at
  /// all is a Data API answer carrying errors, since no other surface raises one under a success.
  static func kind(status: Int, code: APIErrorCode?) -> APIError.Kind {
    switch status {
    case 200...299: .data
    case 400: .badRequest
    case 401: .authentication
    case 402: .billing
    case 403: .forbidden
    case 404: .notFound
    case 405: .methodNotAllowed
    case 409:
      switch code {
      case .idempotencyKeyInUse?: .idempotencyKeyInUse
      case .idempotencyAnswerUnavailable?: .idempotentAnswerUnavailable
      default: .conflict
      }
    case 412: .preconditionFailed
    case 413: .payloadTooLarge
    case 429: .rateLimit
    case 500...599: .server
    default: .other
    }
  }
}
