import Foundation
import Testing

@testable import MountayaClient

@Suite("BinaryResponse")
struct BinaryResponseTests {
  @Test("a file keeps its bytes and the content type the server chose")
  func keepsItsContentType() {
    let file = BinaryResponse(bytes: Data("a,b".utf8), contentType: "text/csv")

    #expect(file.bytes == Data("a,b".utf8))
    #expect(file.contentType == "text/csv")
    #expect(file.status == 200)
    #expect(file.requestId == nil)
  }

  @Test("a file carries the status it arrived with and its request id")
  func carriesItsAnswer() {
    let file = BinaryResponse(
      bytes: Data(), contentType: "application/gpx+xml", status: 200, requestId: "req_7")

    #expect(file.requestId == "req_7")
    #expect(file != BinaryResponse(bytes: Data(), contentType: "application/gpx+xml"))
  }
}
