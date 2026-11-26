import Foundation
import MountayaClient

/// Recorded wraps another exchange and keeps the request id of every answer, which is how a
/// consumer watches its traffic: the client itself records nothing.
struct Recorded: HTTPExchange {
  let wrapping: any HTTPExchange

  func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
    _ = (request.method, request.url, request.headers, request.body, request.header("accept"))
    let response = try await wrapping.send(request)
    _ = (response.status, response.headers, response.header("x-request-id"))
    return response
  }
}

/// Scripted answers every attempt from a script, as a consumer's own test does.
struct Scripted: HTTPExchange {
  func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
    let (chunks, continuation) = AsyncThrowingStream<Data, any Error>.makeStream()
    continuation.yield(Data(#"{"data": null}"#.utf8))
    continuation.finish()
    var answered = ExchangeResponse(status: 200, headers: ["X-Request-Id": "req_a"])
    answered.body = ExchangeBody(chunks: chunks)
    _ = ExchangeBody(Data())
    _ = ExchangeBody { nil }
    _ = ExchangeRequest(method: "GET", url: request.url)
    return answered
  }
}

/// Draws is a random source a test pins.
struct Draws: RandomSource {
  func unitDraw() -> Double {
    0.5
  }

  func cryptographicUuid() -> UUID? {
    UUID(uuidString: "6f1c2a9e-3b4d-4e5f-8a6b-7c8d9e0f1a2b")
  }
}

/// Pinned is a wall clock a consumer's test pins, which a `Retry-After` date and a session
/// token's refresh schedule are read against.
struct Pinned: WallClock {
  let now: Date
}

/// Signals is a session source an app with a session machine of its own conforms. It is
/// Sendable, as every session source is: it stores nothing.
final class Signals: SessionTokenSource {
  var snapshot: SessionSnapshot {
    SessionSnapshot(token: "sess_a", expiresAt: .distantFuture, userId: "us_a")
  }

  func subscribe() -> AsyncStream<SessionSnapshot> {
    AsyncStream { continuation in
      continuation.yield(SessionSnapshot(isMinting: true))
      continuation.finish()
    }
  }
}
