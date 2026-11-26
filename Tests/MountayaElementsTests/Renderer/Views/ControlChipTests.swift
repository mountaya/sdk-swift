import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ControlChip")
@MainActor
struct ControlChipTests {
  @Test("a chip stacks its controls top to bottom on the control ground, a disc for the compass")
  func chips() throws {
    let square = try #require(
      Controls.drawn(
        ControlChip {
          Color.clear.frame(width: 44, height: 44)
          Color.clear.frame(width: 44, height: 44)
        }))
    let disc = try #require(
      Controls.drawn(ControlChip(isRound: true) { Color.clear.frame(width: 44, height: 44) }))

    #expect(square.size == CGSize(width: 44, height: 88))
    #expect(
      Pixels.pixel(square, at: CGPoint(x: 22, y: 66))?.isNear(Controls.color("#ffffff")) == true)
    #expect(
      Pixels.pixel(disc, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#ffffff")) == true)
    #expect((Pixels.pixel(disc, at: CGPoint(x: 2, y: 2))?.alpha ?? 255) < 64, "outside the disc")
  }
}
