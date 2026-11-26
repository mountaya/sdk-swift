import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("TimeSliderWindow")
struct TimeSliderWindowTests {
  /// track is the track starting 2026-03-11T10:26:53.900Z, laid out around 2026-03-14T09:26:53.9Z.
  private static let track = TimeSliderWindow(startMicroseconds: 1_773_224_813_900_000)

  /// milliseconds is an instant in milliseconds from the epoch, as the fixtures write one.
  private static func milliseconds(_ instant: Date?) -> Int64? {
    instant.map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) }
  }

  @Test("a track runs from stop 0 to 215, stop 71 standing for the reading")
  func stops() {
    #expect(Self.track.nowValue == 71)
    #expect(Self.track.maxValue == 215)
    #expect(Self.milliseconds(Self.track.start) == 1_773_224_813_900)
    #expect(Self.milliseconds(Self.track.date(at: 0)) == 1_773_224_813_900)
    #expect(Self.milliseconds(Self.track.date(at: 71)) == 1_773_480_413_900)
    #expect(Self.milliseconds(Self.track.date(at: 215)) == 1_773_998_813_900)
  }

  @Test("a value that is no stop of the track stands for no instant")
  func offTrack() {
    #expect(Self.track.date(at: -1) == nil)
    #expect(Self.track.date(at: 216) == nil)
    #expect(Self.track.date(at: .max) == nil)
  }

  @Test("an instant is placed at its nearest stop, a half hour at the later one, held to the track")
  func placed() {
    let start = 1_773_224_813.9
    #expect(Self.track.value(at: Date(timeIntervalSince1970: start + 71.5 * 3600)) == 72)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: start + 70.5 * 3600)) == 71)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: start + 70.4999 * 3600)) == 70)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: start - 1)) == 0)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: start + 300 * 3600)) == 215)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: 8_640_000_000_000)) == 215)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: -8_640_000_000_000)) == 0)
  }

  @Test("no pin, a pin that names no instant and a track of no instant place the thumb at now")
  func now() {
    #expect(Self.track.value(at: nil) == 71)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: .nan)) == 71)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: .infinity)) == 71)
    #expect(Self.track.value(at: Date(timeIntervalSince1970: 9e12)) == 71)
    let none = TimeSliderWindow(startMicroseconds: nil)
    #expect(none.start == nil)
    #expect(none.value(at: Date(timeIntervalSince1970: 1_773_480_413.9)) == 71)
    #expect(none.date(at: 0) == nil)
    #expect(none.maxValue == 215)
  }

  @Test("two tracks are equal where they start at one instant, or both hold none")
  func equality() {
    #expect(Self.track == TimeSliderWindow(startMicroseconds: 1_773_224_813_900_000))
    #expect(Self.track != TimeSliderWindow(startMicroseconds: 1_773_224_813_900_001))
    #expect(TimeSliderWindow(startMicroseconds: nil) == TimeSliderWindow(startMicroseconds: nil))
  }
}
