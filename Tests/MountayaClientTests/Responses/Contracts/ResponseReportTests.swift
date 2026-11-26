import Testing

@testable import MountayaClient

@Suite("ResponseReport")
struct ResponseReportTests {
  @Test("a report left with no replay, no request id and no state names none")
  func defaults() {
    let report = ResponseReport(operationId: "getZone", surface: .rest, status: 200, attempt: 0)

    #expect(!report.isReplayed)
    #expect(report.requestId == nil)
    #expect(report.rateLimit == nil)
  }
}
