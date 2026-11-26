import Testing

@testable import MountayaClient

@Suite("AttemptBudget")
struct AttemptBudgetTests {
  @Test("the call's budget wins, else the larger of the client's and the operation's plus a margin")
  func budget() {
    #expect(
      AttemptBudget.budget(call: .seconds(1), client: .seconds(30), operation: .seconds(55))
        == .seconds(1))
    #expect(
      AttemptBudget.budget(call: nil, client: .seconds(10), operation: .seconds(30)) == .seconds(35)
    )
    #expect(
      AttemptBudget.budget(call: nil, client: .seconds(120), operation: .seconds(30))
        == .seconds(120))
    #expect(AttemptBudget.budget(call: nil, client: .seconds(10), operation: nil) == .seconds(10))
  }

  @Test("a budget of zero or less is refused")
  func refusesNothing() {
    #expect(throws: MountayaError.self) { try AttemptBudget.check(.zero, as: "The budget") }
    #expect(throws: MountayaError.self) { try AttemptBudget.check(.seconds(-1), as: "The budget") }
    #expect(throws: Never.self) { try AttemptBudget.check(.milliseconds(1), as: "The budget") }
  }
}
