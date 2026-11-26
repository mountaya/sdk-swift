import Testing

@testable import MountayaClient

@Suite("RateLimitState")
struct RateLimitStateTests {
  @Test("a state keeps its policies in the order the answer listed them")
  func order() {
    let state = RateLimitState(policies: [
      RateLimitPolicy(name: "month", quota: 1), RateLimitPolicy(name: "minute", quota: 2),
    ])

    #expect(state.policies.map(\.name) == ["month", "minute"])
  }
}
