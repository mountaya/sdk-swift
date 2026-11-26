import Testing

@testable import MountayaElements

@Suite("accessRefusalStatus")
struct AccessRefusalStatusTests {
  @Test("401, 402 and 403 refuse access, and every other status or none is a fault")
  func statuses() {
    #expect(accessRefusalStatuses == [401, 402, 403])
    #expect((100...599).filter { accessRefusalStatus($0) != nil } == [401, 402, 403])
    #expect(accessRefusalStatus(402) == 402)
    #expect(accessRefusalStatus(nil) == nil)
    #expect(accessRefusalStatus(404) == nil && accessRefusalStatus(429) == nil)
  }
}
