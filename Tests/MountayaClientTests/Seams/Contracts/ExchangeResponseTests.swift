import Foundation
import Testing

@testable import MountayaClient

@Suite("ExchangeResponse")
struct ExchangeResponseTests {
  @Test("a header is read in any letter case, and an answer with no body has an empty one")
  func headerInAnyCase() async throws {
    let response = ExchangeResponse(status: 204, headers: ["x-request-id": "4bf9"])

    #expect(response.header("X-Request-Id") == "4bf9")
    #expect(response.header("ETag") == nil)
    #expect(try await response.body.collect().isEmpty)
  }

  @Test("an answer prints its status alone, however it is printed")
  func redactedWhenPrinted() {
    let response = ExchangeResponse(
      status: 200, headers: ["Set-Cookie": "visit=1", "X-Request-Id": "4bf9"],
      body: ExchangeBody(Data("Refuge".utf8)))

    #expect("\(response)" == "ExchangeResponse(200)")
    #expect(String(reflecting: response) == "ExchangeResponse(200)")
    #expect("\([response])" == "[ExchangeResponse(200)]")

    var dumped = ""
    dump(response, to: &dumped)
    #expect(dumped.contains("ExchangeResponse(200)"))
    for secret in ["visit=1", "4bf9", "Set-Cookie", "Refuge"] {
      #expect(!dumped.contains(secret), "\(secret)")
    }
  }
}
