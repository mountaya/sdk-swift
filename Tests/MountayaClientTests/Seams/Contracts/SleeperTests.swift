import Testing

@testable import MountayaClient

@Suite("Sleeper")
struct SleeperTests {
  private actor RecordingSleeper: Sleeper {
    private(set) var requested: [Duration] = []

    nonisolated var now: Duration {
      .zero
    }

    func sleep(for duration: Duration) async throws {
      requested.append(duration)
    }
  }

  @Test("a conformance sees every wait it is asked for, in order")
  func conformanceSeesEveryWait() async throws {
    let sleeper = RecordingSleeper()
    let seam: any Sleeper = sleeper

    try await seam.sleep(for: .milliseconds(500))
    try await seam.sleep(for: .seconds(30))

    #expect(await sleeper.requested == [.milliseconds(500), .seconds(30)])
  }
}
