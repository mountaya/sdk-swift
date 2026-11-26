import Testing

@testable import MountayaClient

@Suite("HeaderLookup")
struct HeaderLookupTests {
  @Test("a header is found in any letter case, and two spellings of one name are joined")
  func lookup() {
    #expect(HeaderLookup.value(of: "etag", in: ["ETag": "\"d1\""]) == "\"d1\"")
    #expect(HeaderLookup.value(of: "Vary", in: ["Vary": "a", "vary": "b"]) == "a, b")
    #expect(HeaderLookup.value(of: "Location", in: [:]) == nil)
    #expect(HeaderLookup.contains("accept", in: ["Accept": "*/*"]))
  }

  /// Unicode's case mapping lowers the Kelvin sign, U+212A, to an ASCII `k`, so a name spelled
  /// with it would read as `Idempotency-Key` under `lowercased()`.
  @Test("only A to Z fold, so a letter outside ASCII never reads as one inside it")
  func asciiFold() {
    #expect(HeaderLookup.value(of: "Idempotency-Key", in: ["Idempotency-\u{212A}ey": "k"]) == nil)
    #expect(!HeaderLookup.contains("cookie", in: ["Coo\u{212A}ie": "a=b"]))
    #expect(!HeaderLookup.contains("x-share-token", in: ["X-SHARE-TO\u{212A}EN": "shr_1"]))
    #expect(HeaderLookup.asciiLowercase("X-Request-Id") == "x-request-id")
    #expect(HeaderLookup.asciiLowercase("\u{212A}") == "\u{212A}")
    #expect(HeaderLookup.asciiLowercase("\u{130}D é") == "\u{130}d é")
  }

  @Test("a set folded once reads every name as the lookup of it in the set does")
  func folded() {
    let headers = [
      "Vary": "a", "vary": "b", "VARY": "c", "X-Request-Id": "req_1", "content-type": "t",
      "Coo\u{212A}ie": "k", "ETag": "\"d1\"",
    ]
    let folded = HeaderLookup.folded(headers)

    // `VARY` sorts before `Vary`, which sorts before `vary`.
    #expect(
      folded == [
        "vary": "c, a, b", "x-request-id": "req_1", "content-type": "t", "coo\u{212A}ie": "k",
        "etag": "\"d1\"",
      ])
    for name in Array(headers.keys) + ["vary", "ETAG", "Location", "Cookie", "coo\u{212A}ie"] {
      #expect(
        HeaderLookup.value(of: name, inFolded: folded) == HeaderLookup.value(of: name, in: headers),
        "\(name)")
    }
  }

  @Test("a set whose names hold no capital is folded already and comes back as it is")
  func foldedAlready() {
    let headers = ["etag": "\"d1\"", "x-request-id": "req_1", "coo\u{212A}ie": "k"]

    #expect(HeaderLookup.folded(headers) == headers)
    #expect(HeaderLookup.folded([:]).isEmpty)
  }

  @Test("a caller's header spelled with a letter outside ASCII is no header the client writes")
  func clientHeaders() {
    #expect(Transport.clientHeaders.contains(HeaderLookup.asciiLowercase("COOKIE")))
    #expect(!Transport.clientHeaders.contains(HeaderLookup.asciiLowercase("Coo\u{212A}ie")))
  }
}
