import Foundation
import Testing

@testable import MountayaClient

@Suite("ExchangeRequest")
struct ExchangeRequestTests {
  @Test("a header is read in any letter case")
  func headerInAnyCase() throws {
    let url = try #require(URL(string: "https://api.mountaya.com/v1/things"))
    let request = ExchangeRequest(method: "GET", url: url, headers: ["Idempotency-Key": "k"])

    #expect(request.header("idempotency-key") == "k")
    #expect(request.header("IDEMPOTENCY-KEY") == "k")
    #expect(request.header("If-Match") == nil)
  }

  @Test("an attempt prints its method and its address alone, however it is printed")
  func redactedWhenPrinted() throws {
    let url = try #require(URL(string: "https://api.mountaya.com/v1/things?limit=2"))
    let request = ExchangeRequest(
      method: "POST", url: url,
      headers: ["X-Api-Key": "pk_test_abc", "X-Session-Token": "sess_abc", "Cookie": "visit=1"],
      body: Data(#"{"name":"Refuge"}"#.utf8))
    let expected = "ExchangeRequest(POST https://api.mountaya.com/v1/things?limit=2)"

    #expect("\(request)" == expected)
    #expect(String(describing: request) == expected)
    #expect(String(reflecting: request) == expected)
    #expect("\([request])" == "[\(expected)]")

    var dumped = ""
    dump(request, to: &dumped)
    #expect(dumped.contains(expected))
    for secret in ["pk_test_abc", "sess_abc", "visit=1", "Refuge", "X-Api-Key"] {
      #expect(!dumped.contains(secret), "\(secret)")
    }
  }
}
