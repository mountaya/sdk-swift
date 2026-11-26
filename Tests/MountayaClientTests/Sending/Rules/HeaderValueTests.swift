import Testing

@testable import MountayaClient

@Suite("HeaderValue")
struct HeaderValueTests {
  @Test("a value that is empty or whitespace alone is blank, and no other is")
  func blank() {
    #expect(HeaderValue.isBlank(""))
    #expect(HeaderValue.isBlank("   "))
    #expect(HeaderValue.isBlank(" \t "))
    #expect(!HeaderValue.isBlank(" a "))
  }

  @Test("a header carries printable ASCII alone, on every platform")
  func carried() {
    #expect(HeaderValue.isCarried("pk_test_abc"))
    #expect(HeaderValue.isCarried("fr-CH, fr;q=0.9"))
    #expect(HeaderValue.isCarried(" ~!\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`{|}"))
    #expect(HeaderValue.isCarried(""))
    #expect(HeaderValue.uncarried.contains("outside printable ASCII"))
    for refused in [
      "a\nb", "a\rb", "a\tb", "a\u{0}b", "a\u{1F}b", "a\u{7F}b", "a\u{80}b", "a\u{9F}b",
      // A letter of Latin-1 and a no-break space: Apple's loader would write each as one byte
      // and FoundationNetworking's as two, so neither is sent.
      "caf\u{E9}", "a\u{A0}b", "\u{FF}",
      "a\u{100}b", "a\u{2026}b", "😀",
    ] {
      #expect(!HeaderValue.isCarried(refused), "\(refused.debugDescription)")
    }
  }

  @Test("a field name is an RFC 9110 token: letters, digits and the token's symbols alone")
  func token() {
    #expect(HeaderValue.isToken("X-Trace"))
    #expect(HeaderValue.isToken("x_trace.1"))
    #expect(HeaderValue.isToken("!#$%&'*+-.^_`|~"))
    #expect(HeaderValue.isToken("Z9"))
    for refused in [
      "", " ", "X Trace", "X-API-Key: x", "X:Trace", "X\"Trace", "X(Trace)", "X)", "X,Y", "X/Y",
      "X;Y", "X<Y", "X=Y", "X>Y", "X?Y", "X@Y", "X[Y", "X\\Y", "X]Y", "X{Y", "X}Y", "X\tY", "X\nY",
      "X\u{7F}", "caf\u{E9}", "\u{FF21}",
    ] {
      #expect(!HeaderValue.isToken(refused), "\(refused.debugDescription)")
    }
  }
}
