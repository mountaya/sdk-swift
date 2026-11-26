import Testing

@testable import MountayaElements

@Suite("StandingRefusals")
struct StandingRefusalsTests {
  @Test("nothing stands until a source's refusal or one naming none does")
  func empty() {
    #expect(StandingRefusals().isEmpty)
    #expect(!StandingRefusals(sources: ["slope"]).isEmpty)
    #expect(!StandingRefusals(unsourced: true).isEmpty)
  }
}
