import Testing

@testable import MountayaGeo

@Suite("SlopeBucket")
struct SlopeBucketTests {
  @Test("two buckets are equal where they start at one number with texts alike")
  func equality() {
    let flat = SlopeBucket(from: -3, key: "flat", color: "#2f9e44")
    #expect(flat == SlopeBucket(from: -3, key: "flat", color: "#2f9e44"))
    #expect(flat.hashValue == SlopeBucket(from: -3, key: "flat", color: "#2f9e44").hashValue)
    #expect(flat != SlopeBucket(from: 3, key: "flat", color: "#2f9e44"))
    #expect(
      SlopeBucket(from: -.infinity, key: "a", color: "#000")
        == SlopeBucket(from: -.infinity, key: "a", color: "#000"))
  }
}
