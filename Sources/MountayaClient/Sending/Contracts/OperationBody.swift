/// OperationBody is what a request carries, in the media type the operation declares.
package enum OperationBody: Sendable {
  /// none is a request with no body.
  case none
  /// json is a value written as `application/json`. It is written by the transport, so one
  /// encoder writes every body.
  case json(any Encodable & Sendable)
  /// multipart is a form written as `multipart/form-data`, in the order of its parts.
  case multipart([MultipartPart])
}
