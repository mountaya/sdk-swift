import Testing

@testable import MountayaClient

@Suite("EventStreamRules")
struct EventStreamRulesTests {
  @Test("an agent run's stream stops after six reopens and ends on any 5xx but a 503 or a 504")
  func agentRun() {
    #expect(EventStreamRules.agentRun.maxReopens == 6)
    #expect(EventStreamRules.agentRun.maxWait == .seconds(8))
    #expect(EventStreamRules.agentRun.framesBeforeProgress == 1)
    #expect(EventStreamRules.agentRun.endsOnServerError)
  }

  @Test("an agent run's opens answered 503 are held to two minutes, and every arrival is progress")
  func agentRunUnavailable() {
    #expect(EventStreamRules.agentRun.maxUnavailable == .seconds(120))
    #expect(EventStreamRules.agentRun.ownArrivalIsProgress)
  }

  @Test("a collaboration feed never stops on its own, and waits up to 15 seconds")
  func collaborationFeed() {
    #expect(EventStreamRules.collaborationFeed.maxReopens == nil)
    #expect(EventStreamRules.collaborationFeed.maxWait == .seconds(15))
    #expect(EventStreamRules.collaborationFeed.framesBeforeProgress == 0)
    #expect(!EventStreamRules.collaborationFeed.endsOnServerError)
    #expect(EventStreamRules.collaborationFeed.maxUnavailable == nil)
    #expect(EventStreamRules.collaborationFeed.ownArrivalIsProgress)
    #expect(EventStreamRules.stallWindow == .seconds(45))
  }

  @Test("an editor stream is a collaboration feed whose reader's own arrival is no progress")
  func collaborationEditor() {
    let editor = EventStreamRules.collaborationEditor
    let feed = EventStreamRules.collaborationFeed

    #expect(!editor.ownArrivalIsProgress)
    #expect(editor.baseWait == feed.baseWait)
    #expect(editor.maxWait == feed.maxWait)
    #expect(editor.maxReopens == nil)
    #expect(editor.maxUnavailable == nil)
    #expect(editor.framesBeforeProgress == feed.framesBeforeProgress)
    #expect(editor.endsOnServerError == feed.endsOnServerError)
  }
}
