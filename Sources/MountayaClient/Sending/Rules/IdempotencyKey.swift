import Foundation

/// IdempotencyKey decides the `Idempotency-Key` a call sends on every one of its attempts.
enum IdempotencyKey {
  /// header is the header's name.
  static let header = "Idempotency-Key"

  /// key returns the key a call sends, or nil where it sends none.
  ///
  /// An operation that declares no key is sent none, the caller's included, which is then not
  /// read at all. One that declares the header is sent the caller's key as given, refused before
  /// any request where no header can carry it, or else a version 4 UUID drawn once, in its
  /// lowercase canonical form, before the first attempt. Where the runtime offers no
  /// cryptographic source the call sends none, never one drawn from a weaker source.
  static func key(
    declared: Bool,
    given: String?,
    draw: () -> UUID?
  ) throws(MountayaError) -> String? {
    guard declared else { return nil }
    if let given {
      guard !given.isEmpty, HeaderValue.isCarried(given) else {
        throw .configuration(
          ConfigurationError(
            message:
              "The idempotency key is empty, or holds \(HeaderValue.uncarried): pass a key "
              + "such as a UUID."
          )
        )
      }
      return given
    }
    return draw()?.uuidString.lowercased()
  }
}
