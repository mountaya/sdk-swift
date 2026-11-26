import Testing

@testable import MountayaClient

@Suite("RateLimitHeaders")
struct RateLimitHeadersTests {
  @Test("one policy per String member of the policy field, each with its own remaining figures")
  func policies() throws {
    let state = try #require(
      RateLimitHeaders.state(
        policy: #""minute";q=600;w=60, "month";q=1000000;w=2678400"#,
        remaining: #""month";r=420000;t=1209600, "minute";r=0;t=17, "hour";r=3"#
      ))

    #expect(state.policies.map(\.name) == ["minute", "month"])
    #expect(
      state.policies[0]
        == RateLimitPolicy(
          name: "minute", quota: 600, window: .seconds(60), remaining: 0, reset: .seconds(17)))
    #expect(state.policies[1].remaining == 420_000)
  }

  @Test("a member that is no String or has no whole quota is left out, and none left is no state")
  func leftOut() {
    #expect(RateLimitHeaders.state(policy: #"minute;q=60, "month";w=60"#, remaining: nil) == nil)
    #expect(
      RateLimitHeaders.state(policy: #""minute";q=60.5, "address";q=-1"#, remaining: nil) == nil)
    #expect(RateLimitHeaders.state(policy: nil, remaining: #""minute";r=59"#) == nil)
  }

  @Test("a remaining field that does not parse leaves every figure unstated")
  func remainingDoesNotParse() throws {
    let state = try #require(
      RateLimitHeaders.state(policy: #""minute";q=60;w=60"#, remaining: #""minute";r=59;t="#))

    #expect(state.policies == [RateLimitPolicy(name: "minute", quota: 60, window: .seconds(60))])
  }

  @Test("a policy named twice is kept twice, each reading the first figures of its name")
  func namedTwice() throws {
    let state = try #require(
      RateLimitHeaders.state(
        policy: #""minute";q=60, "minute";q=30"#, remaining: #""minute";r=5, "minute";r=9"#))

    #expect(state.policies.map(\.quota) == [60, 30])
    #expect(state.policies.map(\.remaining) == [5, 5])
  }
}
