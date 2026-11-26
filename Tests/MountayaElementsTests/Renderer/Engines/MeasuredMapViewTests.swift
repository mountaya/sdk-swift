import RendererSupport
import Testing
import UIKit

@testable import MountayaElements
@testable import MountayaGeo

@Suite("MeasuredMapView")
@MainActor
struct MeasuredMapViewTests {
  @Test("a map drawn full bleed reads its window's insets, and tells them as it is laid out")
  func fullBleed() throws {
    let map = MeasuredMapView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    var told: [PixelPadding] = []
    map.onSafeArea = { told.append($0) }
    let window = MapWindow.showing(map)
    map.setNeedsLayout()
    map.layoutIfNeeded()

    let insets = window.safeAreaInsets
    let measured = map.measuredSafeArea
    #expect(measured.top == Double(insets.top))
    #expect(measured.left == Double(insets.left))
    #expect(told.last == measured)
    window.isHidden = true
  }

  @Test(
    "an app's own layout cannot rewrite the safe area: a controller's extra insets read nothing")
  func operatingSystemsOwn() throws {
    let host = UIViewController()
    host.additionalSafeAreaInsets = UIEdgeInsets(top: 120, left: 40, bottom: 0, right: 0)
    let map = MeasuredMapView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    host.view.addSubview(map)
    let window = MapWindow.showing(UIView())
    window.rootViewController = host
    host.view.frame = window.bounds
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()

    let insets = window.safeAreaInsets
    #expect(map.safeAreaInsets.top > insets.top, "the controller's extra inset reaches the view")
    #expect(map.measuredSafeArea.top == Double(insets.top))
    #expect(map.measuredSafeArea.left == Double(insets.left))
    window.isHidden = true
  }

  @Test("a map moved in its window with no layout of its own is measured again once told it moved")
  func movedWithNoLayout() async throws {
    let map = MeasuredMapView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    var told: [PixelPadding] = []
    map.onSafeArea = { told.append($0) }
    let holder = UIView()
    holder.addSubview(map)
    let window = MapWindow.showing(holder)
    map.setNeedsLayout()
    map.layoutIfNeeded()
    let visible = MeasuredMapView.screenRect(window.bounds.inset(by: window.safeAreaInsets))

    // The holder carries the map 200 points down the window, the map's own bounds untouched.
    holder.frame.origin.y = 200
    map.measureLater()
    let moved = mapSafeArea(ScreenRect(x: 0, y: 200, width: 390, height: 844), visible: visible)
    #expect(await MapWindow.until { told.last == moved })
    #expect(map.measuredSafeArea == moved, "it passes the window's bottom by 200 points more")
    window.isHidden = true
  }

  @Test("a map in no window reads no safe area")
  func outOfAnyWindow() {
    let map = MeasuredMapView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    #expect(map.measuredSafeArea == PixelPadding(0))
  }
}
