import Testing

@testable import MountayaClient

@Suite("OperationBody")
struct OperationBodyTests {
  @Test("a JSON body holds the value the transport writes")
  func json() throws {
    let body = OperationBody.json(["a": 1] as JSONValue)
    guard case .json(let value) = body else {
      Issue.record("not a JSON body")
      return
    }

    #expect(try ScriptedSender.json(value) == #"{"a":1}"#)
  }
}
