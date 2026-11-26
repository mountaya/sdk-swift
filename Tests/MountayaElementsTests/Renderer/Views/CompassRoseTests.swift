import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("CompassRose")
@MainActor
struct CompassRoseTests {
  private static let needle = Controls.color("#e9501e")

  @Test("the rose's needle points north, and turns against the camera's bearing")
  func needle() throws {
    let north = try #require(Controls.drawn(CompassRose(bearing: 0, size: 32)))
    let south = try #require(Controls.drawn(CompassRose(bearing: 180, size: 32)))

    #expect(Pixels.pixel(north, at: CGPoint(x: 16, y: 9))?.isNear(Self.needle) == true)
    #expect(Pixels.pixel(north, at: CGPoint(x: 16, y: 23))?.isNear(Self.needle) == false)
    #expect(Pixels.pixel(south, at: CGPoint(x: 16, y: 23))?.isNear(Self.needle) == true)
  }

  @Test("the rose's disc is the control ground under the scheme in force")
  func disc() throws {
    let dark = try #require(Controls.drawn(CompassRose(bearing: 0, size: 32), scheme: .dark))

    #expect(Pixels.pixel(dark, at: CGPoint(x: 6, y: 16))?.isNear(Controls.color("#25262b")) == true)
    #expect(
      CompassRose.color(.color(HexColor(hex: "#e9501e")), tokens: .standard, scheme: .dark)
        == hexColor(HexColor(hex: "#e9501e")))
  }
}
