import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("TimeSliderRelease")
struct TimeSliderReleaseTests {
  @Test("a release pins an instant or none, and two are equal where they pin the same")
  func pins() {
    let pinned = Date(timeIntervalSince1970: 1_773_502_013.9)

    #expect(TimeSliderRelease(pin: pinned).pin == pinned)
    #expect(TimeSliderRelease(pin: nil).pin == nil)
    #expect(TimeSliderRelease(pin: pinned) == TimeSliderRelease(pin: pinned))
    #expect(TimeSliderRelease(pin: pinned) != TimeSliderRelease(pin: nil))
  }
}
