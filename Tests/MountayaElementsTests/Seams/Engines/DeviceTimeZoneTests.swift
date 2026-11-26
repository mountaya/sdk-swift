import Foundation
import Testing

@testable import MountayaElements

@Suite("deviceTimeZone")
struct DeviceTimeZoneTests {
  @Test("the zone is the one the system keeps, and names a zone")
  func system() {
    let zone = deviceTimeZone()
    #expect(zone == NSTimeZone.system.identifier)
    #expect(TimeZone(identifier: zone) != nil)
  }
}
