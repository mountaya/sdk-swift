import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("overlayInstant")
struct OverlayInstantTests {
  private static func at(_ milliseconds: Double) -> Date {
    Date(timeIntervalSince1970: milliseconds / 1000)
  }

  private static func milliseconds(_ instant: Date?) -> Double? {
    instant.map { ($0.timeIntervalSince1970 * 1000).rounded() }
  }

  @Test("a pinned instant is itself, behind the clock, ahead of it and under a clock of none")
  func pinned() {
    let pin = Self.at(1_773_480_413_900)
    #expect(overlayInstant(pinned: pin, now: Self.at(1_773_489_600_000)) == pin)
    #expect(overlayInstant(pinned: pin, now: Self.at(1_773_480_000_000)) == pin)
    #expect(overlayInstant(pinned: pin, now: Date(timeIntervalSince1970: .nan)) == pin)
    let early = Self.at(-29_750)
    #expect(overlayInstant(pinned: early, now: Self.at(0)) == early)
  }

  @Test("with none pinned the reading is floored to its minute, one before the epoch included")
  func minute() {
    #expect(
      Self.milliseconds(overlayInstant(pinned: nil, now: Self.at(1_773_489_659_999)))
        == 1_773_489_600_000)
    #expect(
      Self.milliseconds(overlayInstant(pinned: nil, now: Self.at(1_773_489_660_000)))
        == 1_773_489_660_000)
    #expect(Self.milliseconds(overlayInstant(pinned: nil, now: Self.at(-30_000))) == -60_000)
    #expect(Self.milliseconds(overlayInstant(pinned: nil, now: Self.at(-60_000))) == -60_000)
  }

  @Test("a pin that names no instant is none pinned, and a clock of none with none shows none")
  func none() {
    let nothing = Date(timeIntervalSince1970: .nan)
    #expect(
      Self.milliseconds(overlayInstant(pinned: nothing, now: Self.at(1_773_489_659_999)))
        == 1_773_489_600_000)
    #expect(
      Self.milliseconds(
        overlayInstant(
          pinned: Date(timeIntervalSince1970: 9e12), now: Self.at(1_773_489_660_000)))
        == 1_773_489_660_000)
    #expect(overlayInstant(pinned: nil, now: nothing) == nil)
    #expect(overlayInstant(pinned: nothing, now: nothing) == nil)
    #expect(overlayInstant(pinned: nil, now: Date(timeIntervalSince1970: .infinity)) == nil)
    #expect(
      Self.milliseconds(
        overlayInstant(pinned: nil, now: Date(timeIntervalSince1970: 8_640_000_000_059)))
        == 8_640_000_000_000_000, "a reading floored back into the range")
    #expect(
      overlayInstant(pinned: nil, now: Date(timeIntervalSince1970: 8_640_000_000_060)) == nil,
      "a minute past the range the time's rules hold")
  }
}
