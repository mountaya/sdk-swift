import Foundation
import MountayaElements
import Testing

@Suite("MapRequest")
struct MapRequestTests {
  @Test("a request is where it goes and what it carries, each header by its scalars")
  func equality() throws {
    let url = try #require(URL(string: "https://tiles.mountaya.com/v1/zones/1/2/3"))
    let request = MapRequest(url: url, headers: ["X-App": "caf\u{E9}"])

    #expect(request.url == url)
    #expect(request == MapRequest(url: url, headers: ["X-App": "caf\u{E9}"]))
    #expect(request != MapRequest(url: url, headers: ["X-App": "cafe\u{301}"]))
    #expect(request != MapRequest(url: url))
    #expect(MapRequest(url: url).headers.isEmpty)
  }

  @Test("a printed request names its headers and shows no value, a credential's least of all")
  func printed() throws {
    let url = try #require(URL(string: "https://tiles.mountaya.com/v1/zones/1/2/3"))
    let request = MapRequest(
      url: url, headers: ["X-API-Key": "pk_test_secretish", "X-Session-Token": "sess_2c3d"])
    var dumped = ""
    dump(request, to: &dumped)

    #expect(
      request.description
        == "MapRequest(https://tiles.mountaya.com/v1/zones/1/2/3, headers=[X-API-Key, X-Session-Token])"
    )
    for printed in [
      request.description, request.debugDescription, String(describing: request),
      String(reflecting: request), "\(request)", dumped,
    ] {
      #expect(!printed.contains("pk_test_secretish"), "\(printed)")
      #expect(!printed.contains("sess_2c3d"), "\(printed)")
    }
  }
}
