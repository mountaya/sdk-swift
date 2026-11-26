import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements
@testable import MountayaGeo

@Suite("PanelControl")
@MainActor
struct PanelControlTests {
  /// Holder holds a stack's open panel, as a stack's state does.
  @MainActor
  final class Holder {
    var open: MapPanel?

    var binding: Binding<MapPanel?> {
      Binding(get: { self.open }, set: { self.open = $0 })
    }
  }

  @Test("a toggle opens its panel in place of any other in the stack, and closes its own")
  func onePanel() {
    let stack = Holder()

    PanelControl<EmptyView>.toggle(.layers, in: stack.binding)
    #expect(stack.open == .layers)
    PanelControl<EmptyView>.toggle(.preferences, in: stack.binding)
    #expect(stack.open == .preferences, "one panel open at a time")
    PanelControl<EmptyView>.toggle("filters", in: stack.binding)
    #expect(stack.open == "filters", "an app's own panel among them")
    PanelControl<EmptyView>.toggle("filters", in: stack.binding)
    #expect(stack.open == nil)
  }

  @Test("a panel is open where the stack holds it open, or, out of any stack, by its own word")
  func isOpen() {
    let stack = Holder()
    stack.open = .pois

    #expect(PanelControl<EmptyView>.isOpen(.pois, in: stack.binding, alone: false))
    #expect(!PanelControl<EmptyView>.isOpen(.layers, in: stack.binding, alone: true))
    #expect(PanelControl<EmptyView>.isOpen(.layers, in: nil, alone: true))
    #expect(!PanelControl<EmptyView>.isOpen(.layers, in: nil, alone: false))
  }

  @Test(
    "a toggle out of any stack opens its panel beside it in its window's safe area, below the frame a waiting read holds"
  )
  func alone() {
    // A phone's window, its status bar and its home indicator left out.
    let visible = ScreenRect(x: 0, y: 59, width: 390, height: 751)
    let topLeft = AlonePanel.frame(
      in: WindowPlacement(view: ScreenRect(x: 10, y: 69, width: 44, height: 44), visible: visible),
      height: 300)
    #expect(topLeft.x == 10 && topLeft.width == 370, "a narrow safe area's panel fills it")
    #expect(topLeft.y == 55 + watermarkHeight, "below the frame, never beside it")

    let wide = ScreenRect(x: 0, y: 24, width: 1024, height: 700)
    let beside = AlonePanel.frame(
      in: WindowPlacement(view: ScreenRect(x: 10, y: 34, width: 44, height: 44), visible: wide),
      height: 300)
    #expect(beside.x == 62, "beside its toggle, toward the inside of the safe area")
    #expect(beside.y == 20 + watermarkHeight, "and moved below the frame, not to its right")

    let low = AlonePanel.frame(
      in: WindowPlacement(view: ScreenRect(x: 900, y: 400, width: 44, height: 44), visible: wide),
      height: 200)
    #expect(low.x == 900 - 8 - 340 && low.y == 400, "far from the frame, level with its toggle")
  }

  @Test("a toggle standing alone is drawn on a chip of its own, its glyph in the control colour")
  func drawn() throws {
    let image = try #require(
      Controls.drawn(
        PanelControl("filters", label: "Filters", glyph: "zoom-in", content: { Text("Huts") })))

    #expect(image.size == CGSize(width: 44, height: 44))
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 22, y: 22))?.isNear(Controls.color("#212529")) == true)
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 6, y: 22))?.isNear(Controls.color("#ffffff")) == true)
  }
}
