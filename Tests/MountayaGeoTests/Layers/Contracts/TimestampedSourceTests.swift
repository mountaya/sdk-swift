import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("TimestampedSource")
struct TimestampedSourceTests {
  @Test("two sources are equal where their ids and their addresses are, by their scalars")
  func equality() {
    let source = TimestampedSource(sourceId: "snow-depth", tiles: ["https://t/{z}?timestamp=a"])

    #expect(
      source == TimestampedSource(sourceId: "snow-depth", tiles: ["https://t/{z}?timestamp=a"]))
    #expect(source != TimestampedSource(sourceId: "snow", tiles: ["https://t/{z}?timestamp=a"]))
    #expect(source != TimestampedSource(sourceId: "snow-depth", tiles: []))
    #expect(
      TimestampedSource(sourceId: "s", tiles: ["caf\u{E9}"])
        != TimestampedSource(sourceId: "s", tiles: ["cafe\u{301}"]))
  }
}
