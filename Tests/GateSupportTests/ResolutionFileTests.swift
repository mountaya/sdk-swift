import Foundation
import GateSupport
import Testing

@Suite("ResolutionFile")
struct ResolutionFileTests {
  private func hex(_ text: String) -> String {
    ResolutionFile.originHash(ofManifest: Data(text.utf8))
  }

  @Test("a manifest's hash is the SHA-256 of its bytes, FIPS 180-4's own vectors among them")
  func digest() {
    #expect(hex("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    #expect(hex("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    #expect(
      hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
        == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
    #expect(
      hex(String(repeating: "a", count: 1_000))
        == "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
  }

  @Test("a resolution file's hash is read where it holds one, and nil where it holds none")
  func recorded() {
    #expect(
      ResolutionFile.recordedOriginHash(in: #"{ "originHash" : "2468", "pins" : [] }"#) == "2468")
    #expect(ResolutionFile.recordedOriginHash(in: #"{ "pins" : [] }"#) == nil)
    #expect(ResolutionFile.recordedOriginHash(in: "not json") == nil)
  }
}
