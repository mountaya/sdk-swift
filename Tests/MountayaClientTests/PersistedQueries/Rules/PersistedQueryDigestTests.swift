import Testing

@testable import MountayaClient

@Suite("PersistedQueryDigest")
struct PersistedQueryDigestTests {
  @Test("the digest is SHA-256 of the exact bytes, in lowercase hexadecimal")
  func digest() {
    #expect(
      PersistedQueryDigest.digest(of: "")
        == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    #expect(
      PersistedQueryDigest.digest(of: "abc")
        == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  }

  @Test("whitespace and every non-ASCII byte are part of the document")
  func everyByteCounts() {
    let plain = PersistedQueryDigest.digest(of: "query Directions { directions { distance } }")
    let wider = PersistedQueryDigest.digest(of: "query Directions {  directions { distance } }")

    #expect(plain != wider)
    #expect(PersistedQueryDigest.digest(of: "…") != PersistedQueryDigest.digest(of: "..."))
    #expect(plain.count == 64)
    #expect(plain == plain.lowercased())
  }

  @Test("the extension's version is the one the contract sends")
  func version() {
    #expect(PersistedQueryDigest.version == 1)
  }
}
