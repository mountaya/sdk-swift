import Foundation
import Testing

@testable import MountayaClient

@Suite("SystemWallClock")
struct SystemWallClockTests {
  @Test("it reports the platform's current instant")
  func reportsThePlatformInstant() {
    let before = Date()
    let reported = SystemWallClock().now
    let after = Date()

    #expect(before <= reported)
    #expect(reported <= after)
  }
}
