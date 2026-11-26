import Testing

@testable import MountayaClient

@Suite("SystemRandomSource")
struct SystemRandomSourceTests {
  @Test("every draw is at least zero and below one")
  func drawsStayInTheUnitInterval() {
    let source = SystemRandomSource()
    let draws = (0..<1000).map { _ in source.unitDraw() }

    #expect(draws.allSatisfy { $0 >= 0 && $0 < 1 })
    #expect(Set(draws).count > 1)
  }
}
