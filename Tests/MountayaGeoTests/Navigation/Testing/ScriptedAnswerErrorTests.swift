import Testing

@testable import MountayaGeo

@Suite("ScriptedAnswerError")
struct ScriptedAnswerErrorTests {
  @Test("the error says what the test did, in its own words")
  func description() {
    #expect(ScriptedAnswerError(description: "answered twice").description == "answered twice")
  }
}
