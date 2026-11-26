import Foundation
import Testing

@testable import MountayaClient

@Suite("RandomSource")
struct RandomSourceTests {
  private struct FixedRandomSource: RandomSource {
    let draw: Double

    func unitDraw() -> Double {
      draw
    }

    func cryptographicUuid() -> UUID? {
      nil
    }
  }

  @Test("a conformance stands in for the platform's generator")
  func conformanceStandsInForThePlatform() {
    let source: any RandomSource = FixedRandomSource(draw: 0.25)

    #expect(source.unitDraw() == 0.25)
    #expect(source.unitDraw() == 0.25)
    #expect(source.cryptographicUuid() == nil)
  }
}
