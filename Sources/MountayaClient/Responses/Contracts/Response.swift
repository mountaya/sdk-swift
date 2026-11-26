/// Response is what a REST or Tile operation answers: the envelope whole, its `data` and the
/// `metadata` beside it, and what the answer's status and headers say of it.
///
/// `Metadata` is the type the operation declares, where it declares one, and pagination lives
/// there. Where it declares none, `Metadata` is the envelope's open map, which a server may
/// still fill and nothing here reads.
public struct Response<Value: Sendable, Metadata: Sendable>: Sendable {
  /// data is the operation's payload, `JSONValue.null` where the contract types it as null.
  public let data: Value
  /// metadata is the envelope's `extensions.metadata`.
  public let metadata: Metadata
  /// status is the success status the answer arrived with, such as the 201 of a creation or the
  /// 202 of work started.
  public let status: Int
  /// requestId is the answer's `X-Request-Id` exactly as sent, or nil where it sent none.
  public let requestId: String?
  /// location is the answer's `Location`, which a 201 carries, or nil where it sent none.
  public let location: String?
  /// etag is the answer's `ETag` exactly as sent, or nil where it sent none. A resource's own
  /// tag is the one its body states, which is what a conditional write sends back.
  public let etag: String?
  /// headers is every header of the answer, each name in lowercase, `A` to `Z` folded alone, and
  /// a header that arrived more than once holding its values joined by a comma and a space, as
  /// HTTP reads it: the ones the contract declares and any a server or a proxy in front of it
  /// adds. `header(_:)` reads one by its name in any letter case.
  public let headers: [String: String]

  /// Creates a response, such as a test's stand-in for one the API sent, its headers named in
  /// lowercase as an answer's are.
  public init(
    data: Value,
    metadata: Metadata,
    status: Int = 200,
    requestId: String? = nil,
    location: String? = nil,
    etag: String? = nil,
    headers: [String: String] = [:]
  ) {
    self.data = data
    self.metadata = metadata
    self.status = status
    self.requestId = requestId
    self.location = location
    self.etag = etag
    self.headers = HeaderLookup.folded(headers)
  }

  /// header returns the value of a header of the answer, its name read in any letter case, or
  /// nil where the answer sent none.
  public func header(_ name: String) -> String? {
    headers[HeaderLookup.asciiLowercase(name)]
  }
}

extension Response: Equatable where Value: Equatable, Metadata: Equatable {}

extension Response: Hashable where Value: Hashable, Metadata: Hashable {}
