import Foundation
import GateSupport
import Testing

@Suite("ModelDigest")
struct ModelDigestTests {
  /// A vector computed apart, with Python's `hashlib`, over the definition of `sdk/SPEC.md` §11:
  /// each path, a line feed, its length in decimal, a line feed, then its bytes, an empty file and
  /// a letter of two UTF-8 bytes among them.
  @Test("the digest is the SHA-256 the contract defines, each file framed by its path and length")
  func knownVector() {
    let files: [(path: String, bytes: Data)] = [
      ("sdk/model.json", Data("{}\n".utf8)),
      ("sdk/elements/words.json", Data("{\"languages\":{}}\n".utf8)),
      ("sdk/elements/tokens.json", Data()),
      ("sdk/elements/glyphs.json", Data("[]".utf8)),
      ("sdk/elements/NOTICE", Data("Lucide \u{E9}\n".utf8)),
    ]

    #expect(
      ModelDigest.digest(of: files)
        == "3c352238b19206e338f142febc934dca442841543d3ed1574dd6308fdbadb029")
  }

  @Test("the inputs are the contract's five files, in its order")
  func inputs() {
    #expect(
      ModelDigest.inputs == [
        "sdk/model.json", "sdk/elements/words.json", "sdk/elements/tokens.json",
        "sdk/elements/glyphs.json", "sdk/elements/NOTICE",
      ])
  }

  @Test("a byte moved, or a file's bytes read as the next one's path, moves the digest")
  func framing() {
    let joined = ModelDigest.digest(of: [("a", Data("b\nc".utf8)), ("d", Data())])
    let split = ModelDigest.digest(of: [("a", Data("b".utf8)), ("c", Data()), ("d", Data())])

    #expect(joined != split)
    #expect(joined.count == 64)
    #expect(joined.allSatisfy { $0.isHexDigit && !$0.isUppercase })
  }

  @Test("a checkout missing an input names it")
  func missing() {
    let empty = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "no-such-checkout-\(UUID().uuidString)")

    #expect(throws: ModelDigest.Unreadable.self) { try ModelDigest.digest(ofCheckout: empty) }
  }
}
