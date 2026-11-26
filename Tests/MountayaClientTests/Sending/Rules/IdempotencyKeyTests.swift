import Foundation
import Testing

@testable import MountayaClient

@Suite("IdempotencyKey")
struct IdempotencyKeyTests {
  private static let uuid = UUID(uuidString: "6F1C2A9E-3B4D-4E5F-8A6B-7C8D9E0F1A2B")

  @Test("a declared key is the caller's as given, else one drawn, in lowercase")
  func declared() throws {
    #expect(
      try IdempotencyKey.key(declared: true, given: "order-7f3a:1", draw: { nil }) == "order-7f3a:1"
    )
    #expect(
      try IdempotencyKey.key(declared: true, given: nil, draw: { Self.uuid })
        == "6f1c2a9e-3b4d-4e5f-8a6b-7c8d9e0f1a2b")
  }

  @Test("no key is sent where none is declared, nor drawn where no cryptographic source is")
  func none() throws {
    #expect(
      try IdempotencyKey.key(declared: false, given: "order\n7f3a", draw: { Self.uuid }) == nil)
    #expect(try IdempotencyKey.key(declared: true, given: nil, draw: { nil }) == nil)
  }

  @Test("a key no header can carry is refused, the empty one included")
  func refused() {
    for key in ["", "order\n7f3a", "ordre-\u{2116}7", "commande-\u{E9}t\u{E9}"] {
      #expect(throws: MountayaError.self) {
        try IdempotencyKey.key(declared: true, given: key, draw: { Self.uuid })
      }
    }
  }
}
