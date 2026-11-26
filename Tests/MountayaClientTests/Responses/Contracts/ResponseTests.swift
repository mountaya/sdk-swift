import Testing

@testable import MountayaClient

@Suite("Response")
struct ResponseTests {
  @Test("a response carries its data and its metadata, and compares by both")
  func carriesBoth() {
    let response = Response(data: [1, 2], metadata: "page")

    #expect(response.data == [1, 2])
    #expect(response.metadata == "page")
    #expect(response == Response(data: [1, 2], metadata: "page"))
    #expect(response != Response(data: [1, 2], metadata: "other"))
  }

  @Test("every header is kept, named in lowercase, and read back in any letter case")
  func headers() {
    let response = Response(
      data: 1, metadata: 0,
      headers: [
        "X-Request-Id": "req_1", "Content-Type": "application/json", "Vary": "Accept",
        "vary": "Accept-Language",
      ])

    #expect(
      response.headers == [
        "x-request-id": "req_1", "content-type": "application/json",
        "vary": "Accept, Accept-Language",
      ])
    #expect(response.header("CONTENT-TYPE") == "application/json")
    #expect(response.header("Vary") == "Accept, Accept-Language")
    #expect(response.header("ETag") == nil)
    // The Kelvin sign is no `K`: only `A` to `Z` fold.
    #expect(response.header("\u{212A}-x") == nil)
  }
}
