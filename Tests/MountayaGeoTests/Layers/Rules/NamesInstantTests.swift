import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("namesInstant")
struct NamesInstantTests {
  @Test("an instant within 8.64e15 milliseconds of the epoch names one, either side, ends included")
  func within() {
    #expect(namesInstant(Date(timeIntervalSince1970: 0)))
    #expect(namesInstant(Date(timeIntervalSince1970: 1_773_480_413.9)))
    #expect(namesInstant(Date(timeIntervalSince1970: 8_640_000_000_000)))
    #expect(namesInstant(Date(timeIntervalSince1970: -8_640_000_000_000)))
  }

  @Test("a Date of no number, an infinite one, and one past the range name none")
  func none() {
    #expect(!namesInstant(Date(timeIntervalSince1970: .nan)))
    #expect(!namesInstant(Date(timeIntervalSince1970: .infinity)))
    #expect(!namesInstant(Date(timeIntervalSince1970: -.infinity)))
    #expect(!namesInstant(Date(timeIntervalSince1970: 8_640_000_000_000.001)))
    #expect(!namesInstant(Date(timeIntervalSince1970: -8_640_000_000_001)))
  }
}
