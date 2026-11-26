import Foundation
import Testing

@testable import MountayaClient

@Suite("RequestAddress")
struct RequestAddressTests {
  @Test(
    "the path follows the origin, a prefix of its own included, and each query value is encoded")
  func address() throws {
    let origin = try #require(URL(string: "https://proxy.example.com/mountaya/"))
    let url = RequestAddress.url(
      origin: origin,
      path: "/v1/members",
      query: [QueryItem(name: "role", value: "admin"), QueryItem(name: "q", value: "a+b&c=d é")]
    )

    #expect(
      url?.absoluteString
        == "https://proxy.example.com/mountaya/v1/members?role=admin&q=a%2Bb%26c%3Dd%20%C3%A9")
  }

  @Test("no query writes no question mark")
  func noQuery() throws {
    let origin = try #require(URL(string: "https://api.mountaya.com"))

    #expect(
      RequestAddress.url(origin: origin, path: "/v1/zones", query: [])?.absoluteString
        == "https://api.mountaya.com/v1/zones")
  }
}
