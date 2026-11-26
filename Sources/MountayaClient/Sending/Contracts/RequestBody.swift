/// RequestBody is the body a call made by its declaration sends, in a media type its operation
/// takes: a value written as JSON, or a form.
///
/// A printed method writes its operation's body itself; this is for an operation this build
/// prints no method for, `Mountaya.send(_:path:query:headers:body:idempotencyKey:ifMatch:options:)`,
/// so a call reaches it whatever its body. A media type a later build takes is a case of its own,
/// so a `switch` over it outside this module ends in `@unknown default`.
@nonexhaustive
public enum RequestBody: Sendable {
  /// json is a value written as `application/json`, by the encoder every printed method's body
  /// is written by: a printed type, or a `JSONValue`.
  case json(any Encodable & Sendable)
  /// multipart is a form written as `multipart/form-data`, its parts in the order given. A file
  /// part's media type no header can carry is refused with `ConfigurationError` before any
  /// request.
  case multipart([MultipartPart])

  /// payload is the body as the transport writes it.
  var payload: OperationBody {
    switch self {
    case .json(let value): .json(value)
    case .multipart(let parts): .multipart(parts)
    }
  }
}
