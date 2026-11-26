import Testing

@testable import MountayaClient

@Suite("RateLimitPolicy")
struct RateLimitPolicyTests {
  @Test("a figure the answer does not state is none, and a quota holds past 32 bits")
  func unstated() {
    let policy = RateLimitPolicy(name: "share", quota: 5_000_000_000)

    #expect(policy.quota == 5_000_000_000)
    #expect(policy.window == nil)
    #expect(policy.remaining == nil)
    #expect(policy.reset == nil)
  }
}
