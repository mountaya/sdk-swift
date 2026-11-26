import Foundation

/// ExchangeBody is the body of an answer, read a chunk at a time as it arrives.
///
/// An event stream's body has no end for a read to wait on, so the client reads every body this
/// way, a buffered answer included, and decides itself how long a read may take.
public struct ExchangeBody: Sendable {
  private let read: @Sendable () async throws -> Data?

  /// Creates a body read by calling `read`, which returns the next chunk, or nil once the body
  /// has ended, and nil again on every call after that.
  ///
  /// It throws where the body broke off, which the client reads as a dropped connection, and
  /// `CancellationError` once the reading task is cancelled.
  public init(reading read: @escaping @Sendable () async throws -> Data?) {
    self.read = read
  }

  /// Creates a body of the chunks a stream yields, ended when the stream finishes.
  ///
  /// A read whose task is cancelled throws `CancellationError`, where the stream itself would
  /// answer as though it had ended, so a body cut short is never read as a whole one.
  public init(chunks: AsyncThrowingStream<Data, any Error>) {
    self.init {
      var iterator = chunks.makeAsyncIterator()
      if let chunk = try await iterator.next() {
        return chunk
      }
      try Task.checkCancellation()
      return nil
    }
  }

  /// Creates a body that holds `bytes` whole, or none where it is empty.
  public init(_ bytes: Data = Data()) {
    let chunks = AsyncThrowingStream<Data, any Error> { continuation in
      if !bytes.isEmpty {
        continuation.yield(bytes)
      }
      continuation.finish()
    }
    self.init(chunks: chunks)
  }

  /// next returns the next chunk, or nil once the body has ended.
  func next() async throws -> Data? {
    try await read()
  }

  /// collect reads the body to its end.
  func collect() async throws -> Data {
    var bytes = Data()
    while let chunk = try await read() {
      bytes.append(chunk)
    }
    return bytes
  }
}
