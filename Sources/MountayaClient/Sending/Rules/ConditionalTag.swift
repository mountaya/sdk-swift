/// ConditionalTag decides the `If-Match` a conditional write sends.
enum ConditionalTag {
  /// header is the header's name.
  static let header = "If-Match"

  /// tag returns the tag a call sends on every attempt, exactly as its caller named it, or nil
  /// where it sends none.
  ///
  /// The client never writes a tag its caller did not name, whatever tag it has seen: a write
  /// without one replaces what is there, which is what a caller who named none asked for. A tag
  /// no header can carry is refused before any request; anything else is the API's to judge.
  /// An operation that declares no `If-Match` is sent none.
  static func tag(declared: Bool, given: String?) throws(MountayaError) -> String? {
    guard declared, let given else { return nil }
    guard !given.isEmpty, HeaderValue.isCarried(given) else {
      throw .configuration(
        ConfigurationError(
          message:
            "The tag is empty, or holds \(HeaderValue.uncarried): pass the resource's `etag` "
            + "as the API wrote it, or `*`."
        )
      )
    }
    return given
  }
}
