import Foundation
import Testing

@testable import MountayaClient

@Suite("ExchangeBody")
struct ExchangeBodyTests {
  private struct BrokeOff: Error {}

  @Test("a body of bytes is read in one chunk, and an empty one in none")
  func wholeBodies() async throws {
    let body = ExchangeBody(Data("abc".utf8))

    #expect(try await body.next() == Data("abc".utf8))
    #expect(try await body.next() == nil)
    #expect(try await body.next() == nil)
    #expect(try await ExchangeBody().collect().isEmpty)
  }

  @Test("a stream's chunks are read in order and collected whole")
  func chunks() async throws {
    let stream = AsyncThrowingStream<Data, any Error> { continuation in
      continuation.yield(Data("data: ".utf8))
      continuation.yield(Data("a\n\n".utf8))
      continuation.finish()
    }

    #expect(try await ExchangeBody(chunks: stream).collect() == Data("data: a\n\n".utf8))
  }

  @Test("a read its task gives up throws CancellationError, never the end of the body")
  func cancelled() async throws {
    let (stream, continuation) = AsyncThrowingStream<Data, any Error>.makeStream()
    let body = ExchangeBody(chunks: stream)
    let reading = Task { try await body.next() }
    reading.cancel()

    await #expect(throws: CancellationError.self) { try await reading.value }
    continuation.finish()
  }

  @Test("a body that breaks off throws where it broke")
  func brokeOff() async throws {
    let stream = AsyncThrowingStream<Data, any Error> { continuation in
      continuation.yield(Data("a".utf8))
      continuation.finish(throwing: BrokeOff())
    }
    let body = ExchangeBody(chunks: stream)

    #expect(try await body.next() == Data("a".utf8))
    await #expect(throws: BrokeOff.self) { try await body.next() }
  }
}
