import Testing

@testable import MountayaClient

@Suite("RetryPolicy")
struct RetryPolicyTests {
  @Test("the standard policy is the contract's defaults")
  func standardIsTheContracts() throws {
    #expect(RetryPolicy.standard.maxRetries == 2)
    #expect(RetryPolicy.standard.baseDelay == .milliseconds(500))
    #expect(RetryPolicy.standard.maxDelay == .seconds(30))
    #expect(RetryPolicy.standard.waitBudget == .seconds(60))
    #expect(try RetryPolicy() == .standard)
  }

  @Test("each value is overridden on its own")
  func overridesIndependently() throws {
    let policy = try RetryPolicy(maxRetries: 0)
    let budget = try RetryPolicy(waitBudget: .seconds(300))

    #expect(policy.maxRetries == 0)
    #expect(policy.baseDelay == RetryPolicy.standard.baseDelay)
    #expect(policy.maxDelay == RetryPolicy.standard.maxDelay)
    #expect(policy.waitBudget == RetryPolicy.standard.waitBudget)
    #expect(budget.waitBudget == .seconds(300))
    #expect(budget.maxRetries == RetryPolicy.standard.maxRetries)
  }

  @Test(
    "a negative count, delay or budget is refused as a configuration error",
    arguments: [(-1, 500, 30, 60), (2, -1, 30, 60), (2, 500, -1, 60), (2, 500, 30, -1)]
  )
  func refusesNegatives(retries: Int, baseMilliseconds: Int, maxSeconds: Int, budgetSeconds: Int) {
    do {
      _ = try RetryPolicy(
        maxRetries: retries,
        baseDelay: .milliseconds(baseMilliseconds),
        maxDelay: .seconds(maxSeconds),
        waitBudget: .seconds(budgetSeconds)
      )
      Issue.record("a negative value was accepted")
    } catch {
      #expect(error.name == "ConfigurationError")
    }
  }
}
