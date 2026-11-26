import Testing

@testable import MountayaGeo

@Suite("ProfileSpan")
struct ProfileSpanTests {
  @Test("a window, a coloured stretch and a classified stretch are spans the rules read alike")
  func spans() {
    let spans: [any ProfileSpan] = [
      ProfileRange(from: 0, to: 100),
      CurveColor(from: 0, to: 100, color: "#f00"),
      ProfileClass(from: 0, to: 100, color: "#f00", label: "Path"),
    ]
    #expect(spans.allSatisfy { $0.from == 0 && $0.to == 100 })
  }
}
