import Foundation

/// BinaryResponse is what an operation that answers with a file returns: its bytes, the content
/// type the server chose for them, and what the answer's status and headers say of it.
public struct BinaryResponse: Sendable, Hashable {
  /// bytes is the file.
  public let bytes: Data
  /// contentType is the media type the server sent the bytes as, such as
  /// `application/gpx+xml`.
  public let contentType: String
  /// status is the success status the answer arrived with.
  public let status: Int
  /// requestId is the answer's `X-Request-Id` exactly as sent, or nil where it sent none.
  public let requestId: String?

  /// Creates a response, such as a test's stand-in for one the API sent.
  public init(bytes: Data, contentType: String, status: Int = 200, requestId: String? = nil) {
    self.bytes = bytes
    self.contentType = contentType
    self.status = status
    self.requestId = requestId
  }
}
