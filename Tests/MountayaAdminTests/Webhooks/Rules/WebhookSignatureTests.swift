import Foundation
import Testing

@testable import MountayaAdmin

@Suite("WebhookSignature")
struct WebhookSignatureTests {
  @Test("the signature is the contract vector's: HMAC-SHA256 of <t>.<body>, in lowercase hex")
  func vector() {
    #expect(
      WebhookSignature.expected(
        stated: "\(ConstructWebhookEventTests.signedAt)",
        body: Data(ConstructWebhookEventTests.body.utf8),
        secret: ConstructWebhookEventTests.secret
      ) == ConstructWebhookEventTests.vectorSignature)
  }

  @Test("the key is the whole secret, its prefix included, and the t is signed as written")
  func keyAndStated() {
    let body = Data("{}".utf8)
    let whole = WebhookSignature.expected(stated: "5", body: body, secret: "whsk_a")

    #expect(whole != WebhookSignature.expected(stated: "5", body: body, secret: "a"))
    #expect(whole != WebhookSignature.expected(stated: "05", body: body, secret: "whsk_a"))
    #expect(whole.count == 64)
    #expect(whole.allSatisfy { "0123456789abcdef".contains($0) })
  }

  @Test("any candidate that matches verifies, wherever it stands among the others")
  func anyCandidate() {
    #expect(WebhookSignature.verifies(["ab", "cd"], expected: "cd"))
    #expect(WebhookSignature.verifies(["cd", "ab"], expected: "cd"))
    #expect(!WebhookSignature.verifies(["ab", "ce"], expected: "cd"))
    #expect(!WebhookSignature.verifies([], expected: "cd"))
  }

  @Test("two signatures are equal only byte for byte, a length apart never")
  func comparison() {
    #expect(WebhookSignature.equalInConstantTime("ad18", "ad18"))
    #expect(!WebhookSignature.equalInConstantTime("ad19", "ad18"))
    #expect(!WebhookSignature.equalInConstantTime("AD18", "ad18"))
    #expect(!WebhookSignature.equalInConstantTime("ad1", "ad18"))
    #expect(!WebhookSignature.equalInConstantTime("", "ad18"))
  }

  // MARK: - RFC 4231's test cases, which every SDK's HMAC-SHA256 is held to

  /// macHex is the MAC of `message` under `key`, in lowercase hexadecimal.
  private static func macHex(key: [UInt8], message: [UInt8]) -> String {
    WebhookSignature.hex(WebhookSignature.mac(key: key, message: message))
  }

  @Test("a MAC is thirty-two bytes, whatever the message's length")
  func macLength() {
    #expect(WebhookSignature.mac(key: Array("k".utf8), message: []).count == 32)
    #expect(
      WebhookSignature.mac(key: Array("k".utf8), message: Array(repeating: 7, count: 1_000)).count
        == 32)
  }

  @Test("the first four test cases have their MACs")
  func firstFourCases() {
    #expect(
      Self.macHex(key: Array(repeating: 0x0b, count: 20), message: Array("Hi There".utf8))
        == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")
    #expect(
      Self.macHex(key: Array("Jefe".utf8), message: Array("what do ya want for nothing?".utf8))
        == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843")
    #expect(
      Self.macHex(
        key: Array(repeating: 0xaa, count: 20), message: Array(repeating: 0xdd, count: 50))
        == "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe")
    #expect(
      Self.macHex(key: Array(1...25), message: Array(repeating: 0xcd, count: 50))
        == "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b")
  }

  @Test("the truncation case opens with its MAC")
  func truncationCase() {
    #expect(
      Self.macHex(
        key: Array(repeating: 0x0c, count: 20), message: Array("Test With Truncation".utf8)
      )
      .hasPrefix("a3b6167473100ee06e0c796c2955552b"))
  }

  @Test("a key longer than the block is hashed first")
  func longKey() {
    let key = [UInt8](repeating: 0xaa, count: 131)

    #expect(
      Self.macHex(
        key: key, message: Array("Test Using Larger Than Block-Size Key - Hash Key First".utf8))
        == "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54")
    #expect(
      Self.macHex(
        key: key,
        message: Array(
          ("This is a test using a larger than block-size key and a larger than block-size data. "
            + "The key needs to be hashed before being used by the HMAC algorithm.").utf8))
        == "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2")
  }

  @Test("the empty key is the key of zeros it is padded to")
  func emptyKey() {
    #expect(
      Self.macHex(key: [], message: [])
        == "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad")
    let message = Array("Hi There".utf8)
    for key in [[], [0], [UInt8](repeating: 0, count: 64)] as [[UInt8]] {
      #expect(
        Self.macHex(key: key, message: message)
          == "e48411262715c8370cd5e7bf8e82bef53bd53712d007f3429351843b77c7bb9b", "\(key.count)")
    }
  }

  // MARK: - The comparison's twins of every SDK's: equal bytes, a byte apart, a length apart

  @Test("the same bytes are equal, whichever strings hold them")
  func sameBytes() {
    let signature = Self.macHex(
      key: Array(repeating: 0x0b, count: 20), message: Array("Hi There".utf8))
    let copy = String(decoding: Array(signature.utf8), as: UTF8.self)

    #expect(WebhookSignature.equalInConstantTime(signature, signature))
    #expect(WebhookSignature.equalInConstantTime(signature, copy))
    #expect(
      WebhookSignature.equalInConstantTime(
        signature, "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"))
    #expect(WebhookSignature.equalInConstantTime("", ""))
  }

  @Test("one byte that differs, wherever it stands, makes two signatures unequal")
  func oneByteApart() {
    let signature = String(repeating: "a", count: 32)
    for position in [0, 15, 31] {
      var bytes = Array(signature.utf8)
      bytes[position] ^= 0x01
      let flipped = String(decoding: bytes, as: UTF8.self)

      #expect(!WebhookSignature.equalInConstantTime(flipped, signature), "\(position)")
      #expect(!WebhookSignature.equalInConstantTime(signature, flipped), "\(position)")
    }
  }

  @Test("signatures of different lengths are unequal, even where one opens the other")
  func lengthsApart() {
    let signature = String(repeating: "a", count: 32)
    for other in [String(signature.prefix(16)), "", signature + "a"] {
      #expect(!WebhookSignature.equalInConstantTime(other, signature), "\(other.count)")
      #expect(!WebhookSignature.equalInConstantTime(signature, other), "\(other.count)")
    }
  }
}
