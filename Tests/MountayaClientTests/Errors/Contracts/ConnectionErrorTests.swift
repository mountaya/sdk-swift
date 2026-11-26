import Testing

@testable import MountayaClient

@Suite("ConnectionError")
struct ConnectionErrorTests {
  @Test("its message says the request never arrived, and so does a log")
  func describesTheFailure() {
    #expect(ConnectionError().message == "the request never arrived")
    #expect(ConnectionError().description == "the request never arrived")
  }

  @Test("it carries the platform's failure beneath it as its cause")
  func cause() {
    struct Dropped: Error {}
    let error = ConnectionError(idempotencyKey: "key", cause: Dropped())

    #expect(error.cause is Dropped)
    #expect(error.idempotencyKey == "key")
    #expect(ConnectionError().cause == nil)
  }
}
