import Foundation
import Testing

@testable import MountayaClient

@Suite("HTTPExchange")
struct HTTPExchangeTests {
  private struct Echo: HTTPExchange {
    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: request.headers, body: ExchangeBody(request.body ?? Data()))
    }
  }

  @Test("a conformance stands in for the network")
  func conformanceStandsIn() async throws {
    let url = try #require(URL(string: "https://api.mountaya.com/v1/things"))
    let exchange: any HTTPExchange = Echo()
    let response = try await exchange.send(
      ExchangeRequest(method: "POST", url: url, headers: ["A": "b"], body: Data("x".utf8)))

    #expect(response.status == 200)
    #expect(response.header("a") == "b")
    #expect(try await response.body.collect() == Data("x".utf8))
  }
}
