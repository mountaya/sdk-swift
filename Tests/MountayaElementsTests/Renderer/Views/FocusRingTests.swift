import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("FocusRing")
@MainActor
struct FocusRingTests {
  /// square is a control's 44-point ground, white, with the ring a focus `stated` draws around it.
  private static func square(stated: Bool?) -> some View {
    Color.white.frame(width: 44, height: 44).modifier(FocusRing(stated: stated))
  }

  @Test(
    "a control holding the keyboard's focus draws a 2-point ring in focus-ring, inside its frame")
  func drawn() throws {
    let focused = try #require(Controls.drawn(Self.square(stated: true)))

    #expect(focused.size == CGSize(width: 44, height: 44))
    #expect(
      Pixels.pixel(focused, at: CGPoint(x: 1, y: 22))?.isNear(Controls.color("#1c7ed6")) == true)
    #expect(
      Pixels.pixel(focused, at: CGPoint(x: 22, y: 1))?.isNear(Controls.color("#1c7ed6")) == true)
    #expect(
      Pixels.pixel(focused, at: CGPoint(x: 3, y: 22))?.isNear(Controls.color("#ffffff")) == true,
      "the ring is 2 points wide")
    #expect(
      Pixels.pixel(focused, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#ffffff")) == true)
  }

  /// A press focuses no control on a touch screen, so a control a pointer or a finger pressed,
  /// which the focus system never moved to, draws none.
  @Test("a control the keyboard's focus is not on draws no ring")
  func unfocused() throws {
    for stated in [false, nil] {
      let drawn = try #require(Controls.drawn(Self.square(stated: stated)))
      #expect(
        Pixels.pixel(drawn, at: CGPoint(x: 1, y: 22))?.isNear(Controls.color("#ffffff")) == true,
        "\(String(describing: stated))")
    }
    let button = try #require(
      Controls.drawn(
        ControlChip {
          ControlButton(label: "Zoom in", help: "See more detail.") {
          } face: {
            Rectangle().frame(width: 20, height: 20)
          }
        }))
    #expect(
      Pixels.pixel(button, at: CGPoint(x: 1, y: 22))?.isNear(Controls.color("#ffffff")) == true)
  }

  /// The token is a colour of its own: a consumer's accent leaves it as the table states it, the
  /// same in both schemes, and only a consumer's own focus-ring moves it.
  @Test("the ring stands in both schemes, whatever the accent, and takes a consumer's own token")
  func token() throws {
    var accented = ElementTokens.standard
    accented.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
    var ringed = ElementTokens.standard
    ringed.focusRing = ThemeToken(light: HexColor(hex: "#2b8a3e"))
    let dark = try #require(Controls.drawn(Self.square(stated: true), scheme: .dark))
    let accent = try #require(
      Controls.drawn(Self.square(stated: true).mountayaTokens(accented), scheme: .dark))
    let own = try #require(Controls.drawn(Self.square(stated: true).mountayaTokens(ringed)))

    #expect(Pixels.pixel(dark, at: CGPoint(x: 1, y: 22))?.isNear(Controls.color("#1c7ed6")) == true)
    #expect(
      Pixels.pixel(accent, at: CGPoint(x: 1, y: 22))?.isNear(Controls.color("#1c7ed6")) == true)
    #expect(Pixels.pixel(own, at: CGPoint(x: 1, y: 22))?.isNear(Controls.color("#2b8a3e")) == true)
    #expect(FocusRing.width == 2)
  }
}
