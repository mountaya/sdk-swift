import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("PanelSurface")
@MainActor
struct PanelSurfaceTests {
  /// panel is a surface holding a heading and a checked row.
  private static var panel: some View {
    PanelSurface {
      PanelHeading(text: "Base map")
      PanelRow(label: "Satellite", isChecked: true, action: {}) {
        Rectangle().frame(width: 14, height: 14)
      }
    }
  }

  @Test("a panel is drawn on the panel's ground, edged in its border, its text in its colour")
  func drawn() throws {
    let light = try #require(Controls.drawn(Self.panel))
    let dark = try #require(Controls.drawn(Self.panel, scheme: .dark))

    #expect(light.size.width >= 240)
    #expect(Pixels.pixel(light, at: CGPoint(x: 4, y: 4))?.isNear(Controls.color("#ffffff")) == true)
    #expect(Pixels.pixel(dark, at: CGPoint(x: 4, y: 4))?.isNear(Controls.color("#25262b")) == true)
    // The row's mark is drawn in the panel's text colour, at the row's trailing edge.
    let mark = CGPoint(x: light.size.width - 12 - 7, y: light.size.height - 12 - 22)
    #expect(Pixels.pixel(light, at: mark)?.isNear(Controls.color("#212529")) == true)
    #expect(Pixels.pixel(dark, at: mark)?.isNear(Controls.color("#c1c2c5")) == true)
  }

  @Test("a panel is as high as its sections up to its height, and its sections scroll past it")
  func heldHeight() async throws {
    let rows = PanelSurface {
      ForEach(0..<30, id: \.self) { index in
        PanelRow(label: "Layer \(index)", isChecked: false, action: {}) { EmptyView() }
      }
    }
    let (tall, tallWindow) = Hosted.showing(rows)
    let (short, shortWindow) = Hosted.showing(Self.panel)

    #expect(PanelSurface<EmptyView>.maxHeight == 420)
    #expect(
      await MapWindow.until { Hosted.height(tall) == 420 },
      "thirty rows scroll inside the panel's height: \(Hosted.height(tall))")
    #expect(Hosted.height(short) < 420, "a short panel is as high as its sections")
    #expect(Hosted.height(short) >= 12 + 44 + 12)
    tallWindow.isHidden = true
    shortWindow.isHidden = true
  }

  @Test("a row is the platform's touch target high")
  func rowHeight() throws {
    let row = try #require(
      Controls.drawn(PanelRow(label: "Satellite", isChecked: false, action: {}) { EmptyView() }))

    #expect(row.size.height >= 44)
  }
}
