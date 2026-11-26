import MountayaClient
import Foundation
import Testing

@testable import MountayaGeo

@Suite("ReadoutRow")
struct ReadoutRowTests {
  @Test("two rows are equal where they are of one kind holding the same")
  func equality() {
    #expect(ReadoutRow.zoomIn == .zoomIn)
    #expect(ReadoutRow.coordinates(text: "a", copy: "b") != .coordinates(text: "a", copy: "c"))
    #expect(ReadoutRow.instant(Date(timeIntervalSince1970: 0)) != .zoomIn)
    let window = (start: Date?.none, end: Optional(Date(timeIntervalSince1970: 1)), word: "w")
    #expect(
      ReadoutRow.zone(
        name: nil, description: nil, level: "info", levelWord: nil, color: "#1c7ed6",
        window: window)
        == .zone(
          name: nil, description: nil, level: "info", levelWord: nil, color: "#1c7ed6",
          window: window))
    #expect(ReadoutRow.Reading.slope(3, color: "#66bb6a").word == "readout.slope")
  }
}
