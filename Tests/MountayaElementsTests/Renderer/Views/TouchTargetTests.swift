import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("TouchTarget")
@MainActor
struct TouchTargetTests {
  @Test("a view under the touch target is laid out 44 points each way at least, centred in it")
  func padded() throws {
    let small = try #require(
      Controls.drawn(Rectangle().fill(.black).frame(width: 32, height: 32).touchTarget()))
    let wide = try #require(
      Controls.drawn(Rectangle().fill(.black).frame(width: 120, height: 20).touchTarget()))

    #expect(TouchTarget.side == 44)
    #expect(small.size == CGSize(width: 44, height: 44))
    #expect(wide.size == CGSize(width: 120, height: 44), "a span wider than it keeps its width")
    // The 32-point square keeps its look, centred, the padding around it drawn as nothing.
    #expect(Pixels.pixel(small, at: CGPoint(x: 22, y: 22))?.alpha == 255)
    #expect(Pixels.pixel(small, at: CGPoint(x: 3, y: 3))?.alpha == 0)
    #expect(Pixels.pixel(wide, at: CGPoint(x: 60, y: 4))?.alpha == 0)
  }
}
