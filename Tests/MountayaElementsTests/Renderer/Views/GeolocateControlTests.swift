import MountayaClient
import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("GeolocateControl")
@MainActor
struct GeolocateControlTests {
  @Test("a press asks the map for one fix, busy until it settles, each failure handed on")
  func press() async throws {
    let geolocation = Located(.refused(.denied), permission: .prompt)
    let map = try Maps.engine(geolocation: geolocation)
    let engine = GeolocateControlEngine(map: map)
    var failures: [MapError] = []

    GeolocateControl.press(
      engine: engine, onTap: nil,
      onError: { error in
        if let refused = error as? MapError { failures.append(refused) }
      })
    #expect(engine.state.isBusy)
    await settled()

    #expect(!engine.state.isBusy)
    #expect(!engine.state.isBlocked, "a fix refused while the permission was never asked")
    #expect(geolocation.asked == 1)
    #expect(failures == [MapError(kind: .fixRefused(.denied), name: "locate")])
    engine.close()
  }

  @Test("where the reader asked for reduced motion, the fix is framed at once")
  func reducedMotion() async throws {
    let geolocation = Located(
      .located(position: [6.86, 45.83], accuracyMeters: 10), permission: .granted)
    let map = try Maps.engine(geolocation: geolocation)
    let surface = ScriptedMapSurface(drawing: map)
    let engine = GeolocateControlEngine(map: map)

    GeolocateControl.press(
      engine: engine, map: map, reducingMotion: true, onTap: nil, onError: nil)
    await settled()

    #expect(geolocation.asked == 1)
    #expect(surface.frames.last?.fit == CameraFit(maxZoom: 16, duration: .zero))
    engine.close()
  }

  @Test("a handler stands in for the map's fix, which the control then never asks for")
  func handled() async throws {
    let geolocation = Located(
      .located(position: [6.86, 45.83], accuracyMeters: 10), permission: .granted)
    let engine = GeolocateControlEngine(map: try Maps.engine(geolocation: geolocation))
    var taps = 0

    GeolocateControl.press(engine: engine, onTap: { taps += 1 }, onError: nil)
    await settled()

    #expect(taps == 1)
    #expect(geolocation.asked == 0)
    #expect(!engine.state.isBusy)
    engine.close()
  }

  @Test("the control says location is blocked while the permission answers refused, alone")
  func blocked() async throws {
    let refused = try Maps.engine(geolocation: Located(.refused(.denied), permission: .denied))
    let engine = GeolocateControlEngine(map: refused)
    await settled()

    #expect(engine.state.isBlocked)
    #expect(
      GeolocateControl.description(isBlocked: true, in: .standard)
        == "Location is blocked. Allow it in your settings.")
    #expect(
      GeolocateControl.description(isBlocked: false, in: .standard)
        == "Centre the map on where you are.")
    let french = scopeOf(.standard, stating: ElementsScopeStatement(language: "fr"))
    #expect(
      GeolocateControl.description(isBlocked: true, in: french)
        == "Localisation bloquée\u{00A0}: autorisez-la dans vos réglages.")
    engine.close()
  }

  @Test("a busy control is drawn in the accent, and one with no map and no handler is inert")
  func drawn() async throws {
    let map = try Maps.engine(geolocation: Located(.refused(.unavailable), permission: .granted))
    let busy = GeolocateControlEngine()
    busy.configure(map: HeldFix())
    busy.locate()
    let drawnBusy = try #require(Controls.drawn(GeolocateControl(map: map, engine: busy)))
    let idle = try #require(Controls.drawn(GeolocateControl(map: map)))
    let inert = try #require(Controls.drawn(GeolocateControl(map: nil)))
    let owned = try #require(
      Controls.drawn(GeolocateControl(map: nil, isLocating: true, onTap: {})))

    #expect(busy.state.isBusy)
    let accent = Controls.color("#1c7ed6")
    #expect(Self.ink(drawnBusy)?.isNear(accent) == true)
    #expect(Self.ink(idle)?.isNear(Controls.color("#212529")) == true)
    #expect(Self.ink(inert)?.isNear(Controls.color("#adb5bd")) == true)
    #expect(Self.ink(owned)?.isNear(accent) == true, "the app's own fix, said out")
    busy.close()
  }

  /// ink is the colour a control's glyph is drawn in: the pixel of its face's middle row that
  /// stands farthest from the white ground, a stroke's middle, which no edge blends.
  private static func ink(_ image: UIImage) -> Pixels.Pixel? {
    var farthest: (pixel: Pixels.Pixel, distance: Int)?
    for step in 30...102 {
      guard let pixel = Pixels.pixel(image, at: CGPoint(x: Double(step) / 3, y: 22)) else {
        continue
      }
      let distance = (255 - pixel.red) + (255 - pixel.green) + (255 - pixel.blue)
      if distance > farthest?.distance ?? 0 {
        farthest = (pixel, distance)
      }
    }
    return farthest?.pixel
  }

  /// HeldFix is a map whose fix never answers, so the control stays busy.
  @MainActor
  final class HeldFix: GeolocateControlTarget {
    func locate() async throws -> [Double] {
      try await Task.sleep(for: .seconds(3_600))
      return []
    }

    func isLocationRefused() async -> Bool { false }
  }
}
