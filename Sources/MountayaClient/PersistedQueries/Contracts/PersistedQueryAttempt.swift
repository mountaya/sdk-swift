/// PersistedQueryAttempt is what one attempt of a Data API operation sends of its document: the
/// digest alone, the document alone, or both.
struct PersistedQueryAttempt: Sendable, Hashable {
  /// digest is the persisted-query digest the attempt sends, or nil where it sends none.
  let digest: String?
  /// sendsDocument is true where the attempt sends the document itself.
  let sendsDocument: Bool

  /// isDigestOnly is true for an attempt that sends a digest and leaves the document out, which
  /// is the one attempt a server answers by asking for the document.
  var isDigestOnly: Bool {
    digest != nil && !sendsDocument
  }
}
