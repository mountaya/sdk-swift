import Testing

@testable import MountayaGeo

@Suite("sameValue")
struct SameValueTests {
  @Test("two numbers are compared as the same numbers, and any other values by their own ==")
  func values() {
    #expect(sameValue(Double.nan, Double.nan))
    #expect(!sameValue(0.0, -0.0))
    #expect(sameValue(5.0, 5.0))
    #expect(sameValue("gravel", "gravel"))
    #expect(!sameValue("gravel", "asphalt"))
    #expect(sameValue(3, 3))
  }

  @Test("two lists of numbers are compared number by number, as the same numbers")
  func lists() {
    #expect(sameValue([6, Double.nan], [6, -.nan]))
    #expect(!sameValue([0.0], [-0.0]))
    #expect(!sameValue([6.0, 45], [45, 6]))
    #expect(sameValue([HexColor](), []))
  }

  @Test("an absent value is the same only as another absent one")
  func absent() {
    #expect(sameValue(Double?.none, nil))
    #expect(sameValue(Double?.some(.nan), -.nan))
    #expect(!sameValue(Double?.some(0), -0.0))
    #expect(!sameValue(nil, Double?.some(0)))
    #expect(sameValue([Double]?.some([.nan]), [-.nan]))
    func hashed(_ value: Double?) -> Int {
      var hasher = Hasher()
      hasher.combine(sameValue: value)
      return hasher.finalize()
    }
    #expect(hashed(.nan) == hashed(-.nan))
    #expect(hashed(nil) == hashed(nil))
    #expect(hashed(nil) != hashed(0))
  }

  @Test("two values the relation calls the same hash alike")
  func hashing() {
    func hashed<Value: Hashable>(_ value: Value) -> Int {
      var hasher = Hasher()
      hasher.combine(sameValue: value)
      return hasher.finalize()
    }
    #expect(hashed(Double.nan) == hashed(-Double.nan))
    #expect(hashed(0.0) != hashed(-0.0))
    #expect(hashed("gravel") == hashed("gravel"))
    #expect(hashed([6, Double.nan]) == hashed([6, -Double.nan]))
    #expect(hashed([0.0]) != hashed([-0.0]))
  }
}
