import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ControlButton")
@MainActor
struct ControlButtonTests {
  /// button is a control on its chip, a block filling its face.
  private static func button(isBusy: Bool = false, isHeld: Bool = false) -> some View {
    ControlChip {
      ControlButton(label: "Zoom in", help: "See more detail.", isBusy: isBusy, isHeld: isHeld) {
      } face: {
        Rectangle().frame(width: 20, height: 20)
      }
    }
  }

  @Test("a face is drawn in the control's colour, the accent while busy, dimmed while disabled")
  func faceTokens() {
    #expect(ControlButton<EmptyView>.faceToken(isEnabled: true, isBusy: false) == \.controlFg)
    #expect(ControlButton<EmptyView>.faceToken(isEnabled: true, isBusy: true) == \.accent)
    #expect(
      ControlButton<EmptyView>.faceToken(isEnabled: false, isBusy: true) == \.controlFgDisabled)
    #expect(ControlButton<EmptyView>.groundToken(isHovered: false, isHeld: false) == nil)
    #expect(
      ControlButton<EmptyView>.groundToken(isHovered: true, isHeld: false) == \.controlBgHover)
    #expect(
      ControlButton<EmptyView>.groundToken(isHovered: false, isHeld: true) == \.controlBgHover)
  }

  @Test("a control is drawn in the tokens under the scheme in force, the touch target across")
  func drawn() throws {
    let light = try #require(Controls.drawn(Self.button()))
    let dark = try #require(Controls.drawn(Self.button(), scheme: .dark))

    #expect(light.size == CGSize(width: 44, height: 44))
    #expect(
      Pixels.pixel(light, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#212529")) == true)
    #expect(
      Pixels.pixel(light, at: CGPoint(x: 6, y: 22))?.isNear(Controls.color("#ffffff")) == true)
    #expect(
      Pixels.pixel(dark, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#c1c2c5")) == true)
    #expect(Pixels.pixel(dark, at: CGPoint(x: 6, y: 22))?.isNear(Controls.color("#25262b")) == true)
  }

  @Test("a busy face is the accent, a disabled one dimmed, a held one on the hover ground")
  func states() throws {
    let busy = try #require(Controls.drawn(Self.button(isBusy: true)))
    let disabled = try #require(Controls.drawn(Self.button(isBusy: true).disabled(true)))
    let held = try #require(Controls.drawn(Self.button(isHeld: true)))

    #expect(
      Pixels.pixel(busy, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#1c7ed6")) == true)
    #expect(
      Pixels.pixel(disabled, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#adb5bd")) == true)
    #expect(Pixels.pixel(held, at: CGPoint(x: 6, y: 22))?.isNear(Controls.color("#f1f3f5")) == true)
  }

  @Test("a consumer's tokens are the ones drawn, a value it states standing in both schemes")
  func consumerTokens() throws {
    var tokens = ElementTokens.standard
    tokens.controlBg = ThemeToken(light: HexColor(hex: "#000000"))
    tokens.controlFg = ThemeToken(light: HexColor(hex: "#e9501e"))
    let dark = try #require(Controls.drawn(Self.button().mountayaTokens(tokens), scheme: .dark))

    #expect(
      Pixels.pixel(dark, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#e9501e")) == true)
    #expect(Pixels.pixel(dark, at: CGPoint(x: 6, y: 22))?.isNear(Controls.color("#000000")) == true)
  }
}
