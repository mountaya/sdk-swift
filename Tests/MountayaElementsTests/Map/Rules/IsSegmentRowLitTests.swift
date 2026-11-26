import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("isSegmentRowLit")
struct IsSegmentRowLitTests {
  private let valley = segmentRow("valley", from: 0, to: 400)
  private let climb = segmentRow("group:climb", from: 400, to: 1000, members: ["lower", "upper"])

  @Test("a row is lit where it is pointed at, and where the map's cursor is over its leg")
  func pointedOrHovered() {
    #expect(isSegmentRowLit(valley, pointed: "valley", highlighted: nil, hovered: nil))
    #expect(isSegmentRowLit(valley, pointed: nil, highlighted: nil, hovered: "valley"))
    #expect(isSegmentRowLit(climb, pointed: nil, highlighted: nil, hovered: "upper"))
    #expect(!isSegmentRowLit(valley, pointed: nil, highlighted: nil, hovered: "upper"))
    #expect(!isSegmentRowLit(valley, pointed: nil, highlighted: nil, hovered: nil))
  }

  @Test("a row the app names is lit in place of the one the map's cursor would light")
  func highlighted() {
    #expect(isSegmentRowLit(climb, pointed: nil, highlighted: "group:climb", hovered: "valley"))
    #expect(!isSegmentRowLit(valley, pointed: nil, highlighted: "group:climb", hovered: "valley"))
    #expect(isSegmentRowLit(valley, pointed: "valley", highlighted: "group:climb", hovered: nil))
  }
}
