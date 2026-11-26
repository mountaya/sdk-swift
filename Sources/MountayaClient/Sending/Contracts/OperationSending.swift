/// OperationSending is the seam every generated method sends through.
///
/// A generated method builds what the operation declares and what the call fills in, and
/// hands it here with the shape of the answer it returns. Behind the seam is the whole
/// pipeline: the credential's headers, retries, the envelope, the error ladder and decoding.
/// A test puts a scripted sender here, so a generated method is held to the contract without a
/// network.
///
/// It is `package` rather than `internal` because the admin unit's printed methods, in
/// `MountayaAdmin`, send through it as the core's do; no consumer of the package reaches it
/// (SPEC.md section 2).
///
/// Each requirement throws a `MountayaError`, or `CancellationError` when the calling task is
/// cancelled, which is never wrapped.
package protocol OperationSending: Sendable {
  /// envelope sends a request whose success is a JSON envelope, and returns its `data` and its
  /// `extensions.metadata` as the types the operation declares.
  func envelope<Value: Decodable & Sendable, Metadata: Decodable & Sendable>(
    _ request: OperationRequest,
    options: RequestOptions
  ) async throws -> Response<Value, Metadata>

  /// binary sends a request whose success is a file, and returns its bytes and content type.
  func binary(_ request: OperationRequest, options: RequestOptions) async throws
    -> BinaryResponse

  /// events prepares a request whose success is an event stream, and returns its frames, each
  /// event decoded as the type the operation declares. It awaits nothing: the stream opens as its
  /// first frame is asked for, and it throws only what it refuses before any request.
  func events<Event: StreamedEvent>(
    _ request: OperationRequest,
    options: RequestOptions
  ) throws -> EventStream<Event>

  /// query sends a Data API operation with its input and the caller's selection, and returns
  /// its result.
  func query<Input: Encodable & Sendable, Result: Decodable & Sendable>(
    _ operation: DataOperation,
    facts: OperationFacts,
    input: Input,
    select: FieldSelection?,
    options: RequestOptions
  ) async throws -> Result
}
