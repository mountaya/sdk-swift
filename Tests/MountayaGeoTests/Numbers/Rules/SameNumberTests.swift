import Testing

@testable import MountayaGeo

@Suite("sameNumber")
struct SameNumberTests {
  @Test("a number is the same as itself and no other")
  func itself() {
    #expect(sameNumber(6.8652, 6.8652))
    #expect(sameNumber(.infinity, .infinity))
    #expect(!sameNumber(6.8652, 6.8653))
    #expect(!sameNumber(.infinity, -.infinity))
  }

  @Test("NaN is the same as NaN, whatever its payload, and the two zeros are two numbers")
  func notANumberAndTheZeros() {
    #expect(sameNumber(.nan, .nan))
    #expect(sameNumber(.nan, Double(bitPattern: 0x7ff8_0000_0000_0001)))
    #expect(sameNumber(.nan, -.nan))
    #expect(!sameNumber(.nan, 0))
    #expect(!sameNumber(0, -0.0))
    #expect(sameNumber(-0.0, -0.0))
  }

  @Test("two lists are the same numbers in the same order")
  func lists() {
    #expect(sameNumbers([6, .nan], [6, .nan]))
    #expect(sameNumbers([], []))
    #expect(!sameNumbers([6, 45], [45, 6]))
    #expect(!sameNumbers([6, 45], [6, 45, 1000]))
    #expect(!sameNumbers([0], [-0.0]))
  }

  @Test("two numbers the relation calls the same hash alike, and two it tells apart do not")
  func hashing() {
    func hash(_ feed: (inout Hasher) -> Void) -> Int {
      var hasher = Hasher()
      feed(&hasher)
      return hasher.finalize()
    }

    #expect(
      hash { $0.combine(sameNumber: .nan) }
        == hash { $0.combine(sameNumber: Double(bitPattern: 0x7ff8_0000_0000_0001)) })
    #expect(hash { $0.combine(sameNumber: 0) } != hash { $0.combine(sameNumber: -0.0) })
    #expect(
      hash { $0.combine(sameNumbers: [6, .nan]) } == hash { $0.combine(sameNumbers: [6, .nan]) })
    #expect(sameNumberBits(-.nan) == sameNumberBits(.nan))
  }

  @Test("an absent figure is the same only as another absent one, and hashes apart from a number")
  func absentFigures() {
    #expect(sameNumber(Double?.none, nil))
    #expect(sameNumber(Double?.some(.nan), .nan))
    #expect(!sameNumber(nil, Double?.some(0)))
    #expect(!sameNumber(Double?.some(0), nil))
    #expect(!sameNumber(Double?.some(0), -0.0))
    func hashed(_ value: Double?) -> Int {
      var hasher = Hasher()
      hasher.combine(sameNumber: value)
      return hasher.finalize()
    }
    #expect(hashed(nil) == hashed(nil))
    #expect(hashed(nil) != hashed(0))
    #expect(hashed(.nan) == hashed(-.nan))
  }
}
