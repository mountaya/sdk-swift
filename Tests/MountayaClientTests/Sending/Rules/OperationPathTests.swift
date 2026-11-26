import Testing

@testable import MountayaClient

@Suite("OperationPath")
struct OperationPathTests {
  @Test("each parameter fills its placeholder, percent-encoded as one segment")
  func substitute() {
    let path = OperationPath.substitute(
      "/v1/itineraries/{itinerary_id}/segments/{segment_id}",
      with: ["segment_id": "s 1", "itinerary_id": "a/b"]
    )

    #expect(path == "/v1/itineraries/a%2Fb/segments/s%201")
  }

  @Test("only RFC 3986's unreserved characters stay as written")
  func unreserved() {
    #expect(OperationPath.segment("Az09-._~") == "Az09-._~")
    #expect(OperationPath.segment("?#%&+=:@") == "%3F%23%25%26%2B%3D%3A%40")
    #expect(OperationPath.segment("é") == "%C3%A9")
  }
}
