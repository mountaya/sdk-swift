import Foundation
import Testing

@testable import MountayaClient

@Suite("WallClock")
struct WallClockTests {
  private struct FixedWallClock: WallClock {
    let now: Date
  }

  /// Refusing answers every attempt with a 429 whose `Retry-After` is an HTTP date.
  private struct Refusing: HTTPExchange {
    let retryAfter: String

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: 429,
        headers: ["Content-Type": "application/json", "Retry-After": retryAfter],
        body: ExchangeBody(Data(#"{"errors": [{"message": "Slow down."}]}"#.utf8)))
    }
  }

  @Test("a conformance stands in for the platform's clock")
  func conformanceStandsInForThePlatform() {
    let instant = Date(timeIntervalSince1970: 1_800_000_000)
    let clock: any WallClock = FixedWallClock(now: instant)

    #expect(clock.now == instant)
  }

  @Test("a client's `Retry-After` date is read against the wall clock it is handed")
  func retryAfterDate() async throws {
    // Sun, 06 Nov 1994 08:49:37 GMT, read 25 seconds before it and then a second after it.
    let date = Date(timeIntervalSince1970: 784_111_777)
    var waits: [Duration?] = []
    for offset in [-25.0, 1] {
      let client = try Mountaya(
        credential: .publishable(key: "pk_test_a"), retry: try RetryPolicy(maxRetries: 0),
        exchange: Refusing(retryAfter: "Sun, 06 Nov 1994 08:49:37 GMT"),
        wallClock: FixedWallClock(now: date.addingTimeInterval(offset)))
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          OperationDeclaration(operationId: "readThing", method: "GET", idempotent: true),
          path: "/v1/things")
        Issue.record("a 429 was answered as a success")
      } catch let error as MountayaError {
        guard case .api(let refusal) = error else {
          Issue.record("refused as \(error.name)")
          continue
        }
        waits.append(refusal.retryAfter)
      }
    }

    #expect(waits == [.seconds(25), .zero])
  }
}
