import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("OrganizationRead")
struct OrganizationReadTests {
  @Test("an answer holds whether the organization holds white label")
  func answered() {
    #expect(OrganizationRead.answered(whiteLabel: true) != .answered(whiteLabel: false))
    #expect(OrganizationRead.failed != .noKey)
    #expect(OrganizationRead.timedOut != .waiting)
  }
}
