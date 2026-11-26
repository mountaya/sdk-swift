import SwiftUI
import Testing

@testable import MountayaElements

@Suite("MapCorner")
struct MapCornerTests {
  @Test("a corner stands where the reader sees it, whichever way the text runs")
  func alignment() {
    #expect(MapCorner.topRight.alignment(in: .leftToRight) == .topTrailing)
    #expect(MapCorner.topRight.alignment(in: .rightToLeft) == .topLeading)
    #expect(MapCorner.topLeft.alignment(in: .leftToRight) == .topLeading)
    #expect(MapCorner.topLeft.alignment(in: .rightToLeft) == .topTrailing)
    #expect(MapCorner.bottomRight.alignment(in: .leftToRight) == .bottomTrailing)
    #expect(MapCorner.bottomRight.alignment(in: .rightToLeft) == .bottomLeading)
    #expect(MapCorner.bottomLeft.alignment(in: .leftToRight) == .bottomLeading)
    #expect(MapCorner.bottomLeft.alignment(in: .rightToLeft) == .bottomTrailing)
  }
}
