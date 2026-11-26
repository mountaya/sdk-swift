import Testing

@testable import MountayaClient

@Suite("OpenFailure")
struct OpenFailureTests {
  private static func ends(_ status: Int, rules: EventStreamRules) -> Bool {
    OpenFailure.ends(.api(APIError(status: status)), rules: rules)
  }

  @Test("a 4xx but a 429 ends either stream, a 429, a 503, a 504 and a drop reopen either")
  func either() {
    for rules in [EventStreamRules.agentRun, .collaborationFeed] {
      #expect(Self.ends(401, rules: rules))
      #expect(Self.ends(402, rules: rules))
      #expect(!Self.ends(429, rules: rules))
      #expect(!Self.ends(503, rules: rules))
      #expect(!Self.ends(504, rules: rules))
      #expect(!OpenFailure.ends(.connection(ConnectionError()), rules: rules))
      #expect(
        OpenFailure.ends(.configuration(ConfigurationError(message: "refused")), rules: rules))
    }
  }

  @Test("every other 5xx ends an agent run's stream and reopens a collaboration feed")
  func perStream() {
    for status in [500, 501, 502] {
      #expect(Self.ends(status, rules: .agentRun))
      #expect(!Self.ends(status, rules: .collaborationFeed))
    }
  }
}
