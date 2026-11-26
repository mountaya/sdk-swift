import Testing

@testable import MountayaClient

@Suite("EventFrame")
struct EventFrameTests {
  @Test("a frame carries its event and the id a caller resumes from")
  func carriesItsId() {
    let frame = EventFrame(id: "7", event: "delta")

    #expect(frame.id == "7")
    #expect(frame.event == "delta")
    #expect(frame != EventFrame(id: nil, event: "delta"))
  }
}
