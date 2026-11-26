import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("StripePattern")
struct StripePatternTests {
  private static func pattern(
    ground: String? = "#ffffff", segments: [[[Double]]] = [[[0, 16], [16, 0]]]
  )
    -> StripePattern
  {
    StripePattern(
      size: 16, width: 4, color: "#f03e3e", ground: ground, lineCap: .round, segments: segments)
  }

  @Test("two patterns are equal where every member is, every stripe's ends the same numbers")
  func equality() {
    #expect(Self.pattern() == Self.pattern())
    #expect(Self.pattern(ground: nil) != Self.pattern())
    #expect(Self.pattern(ground: nil) == Self.pattern(ground: nil))
    #expect(Self.pattern(segments: [[[0, 16], [16, -0.0]]]) != Self.pattern())
    #expect(Self.pattern(segments: []) != Self.pattern())
    #expect(Self.pattern(segments: [[[0, 16]]]) != Self.pattern())
  }
}
