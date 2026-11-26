import RendererSupport
import SwiftUI
import Testing
import UIKit

@testable import MountayaElements
@testable import MountayaGeo

@Suite("WindowProbe")
@MainActor
struct WindowProbeTests {
  @Test("a probe reads where the view it marks stands in its window, and the part left visible")
  func placed() {
    let view = WindowProbeView(frame: CGRect(x: 20, y: 100, width: 0, height: 0))
    view.size = CGSize(width: 300, height: 400)
    var told: [WindowPlacement?] = []
    view.onPlaced = { told.append($0) }
    let window = MapWindow.showing(UIView())
    window.addSubview(view)

    view.measure()
    let insets = window.safeAreaInsets
    let placement = view.placement
    #expect(placement?.view == ScreenRect(x: 20, y: 100, width: 300, height: 400))
    #expect(placement?.visible.y == Double(insets.top))
    #expect(told.last == placement)
    view.measure()
    #expect(told.count == 1, "a placement that stands still is told once")
    window.isHidden = true
  }

  @Test("a probe in no window reads none")
  func outOfAnyWindow() {
    let view = WindowProbeView(frame: .zero)
    var told: [WindowPlacement?] = []
    view.onPlaced = { told.append($0) }
    view.measure()
    #expect(view.placement == nil)
    #expect(told == [nil])
  }

  @Test("a probe takes no room, so nothing of it is drawn")
  func noRoom() throws {
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          WindowProbe(moved: CGRect(x: 0, y: 0, width: 100, height: 100)) { _ in }
        }
        .frame(width: 100, height: 100)))
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 50, y: 50))?.isNear(Controls.color("#000000")) == true)
  }
}
