/// PersistedQueryRefusal is what a server's errors mean in answer to an attempt that sent a
/// persisted-query digest.
///
/// It is read before the rule that a Data API answer carrying errors is a failure, since the
/// ordinary answer to a digest the server does not hold yet is one. Each refusal is recognised
/// in both spellings a server uses, by its message alone or also by its code, since a client
/// that read only one would miss half the servers it meets.
enum PersistedQueryRefusal: Sendable, Hashable {
  /// register is the server asking for the document, since it does not hold this digest yet.
  /// The request is sent again with both, and the digest is dropped rather than remembered.
  case register
  /// unsupported is the server declining the protocol, which turns persisted queries off for
  /// the lifetime of the transport rather than for one call.
  case unsupported

  static let registerMessages: Set<String> = ["PersistedQueryNotFound"]
  static let registerCodes: Set<APIErrorCode> = ["PERSISTED_QUERY_NOT_FOUND"]
  static let unsupportedMessages: Set<String> = ["PersistedQueryNotSupported"]
  static let unsupportedCodes: Set<APIErrorCode> = ["PERSISTED_QUERY_NOT_SUPPORTED"]
  /// unsupportedEntries is the entries that decline the protocol only by their code and their
  /// message together, and only in answer to a digest-only attempt: the Data API with the
  /// extension turned off finds no operation in a body that carries no document.
  static let unsupportedEntries: [(code: APIErrorCode, message: String)] = [
    (code: "GRAPHQL_VALIDATION_FAILED", message: "no operation provided")
  ]

  /// Reads the errors that answered `attempt`, or returns nil where none is a refusal: an
  /// ordinary error reaches the caller untouched.
  ///
  /// Any entry may carry the refusal, whatever its place, and an entry declining the protocol is
  /// read before one asking for the document, since the first is a statement about the server
  /// and the second about one document. Only a digest-only attempt is asked for its document, so
  /// an attempt that sent the document reads a declined protocol alone, and one that sent no
  /// digest reads no refusal at all.
  init?(errors: [ErrorEntry], answering attempt: PersistedQueryAttempt) {
    guard attempt.digest != nil else { return nil }
    let declines = errors.contains { entry in
      Self.spells(entry, messages: Self.unsupportedMessages, codes: Self.unsupportedCodes)
        || (attempt.isDigestOnly && Self.isUnsupportedEntry(entry))
    }
    let asks =
      attempt.isDigestOnly
      && errors.contains {
        Self.spells($0, messages: Self.registerMessages, codes: Self.registerCodes)
      }
    if declines {
      self = .unsupported
    } else if asks {
      self = .register
    } else {
      return nil
    }
  }

  /// spells is whether an entry carries a refusal by its message alone or by its code.
  private static func spells(
    _ entry: ErrorEntry, messages: Set<String>, codes: Set<APIErrorCode>
  )
    -> Bool
  {
    messages.contains(entry.message) || entry.code.map(codes.contains) == true
  }

  /// isUnsupportedEntry is whether an entry carries one of `unsupportedEntries`' code and
  /// message together.
  private static func isUnsupportedEntry(_ entry: ErrorEntry) -> Bool {
    unsupportedEntries.contains { $0.code == entry.code && $0.message == entry.message }
  }
}
