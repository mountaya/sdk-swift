import MountayaClient
import MountayaElements
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements
@testable import MountayaGeo

@Suite("MapControls")
@MainActor
struct MapControlsTests {
  private static let needle = Controls.color("#e9501e")
  private static let ink = Controls.color("#212529")

  /// laid lays `controls` over a dark square 400 points across, as a map they float over, wide
  /// enough that a stack in any corner stands clear of the frame a waiting read holds.
  private static func laid(_ controls: some View) -> some View {
    ZStack {
      Color.black
      controls
    }
    .frame(width: 400, height: 400)
  }

  @Test("the stack reads zoom above the compass, top right unless another corner is named")
  func order() throws {
    let map = try Maps.engine()
    let topRight = try #require(
      Controls.drawn(
        Self.laid(MapControls(map, zoom: true, compass: true, layers: false, preferences: false))))
    let bottomLeft = try #require(
      Controls.drawn(
        Self.laid(
          MapControls(
            map, zoom: true, compass: true, layers: false, preferences: false,
            corner: .bottomLeft))))

    // Top right: the zoom chip 10 points in from the corner, its plus at its first button's
    // middle, and the compass 8 points under the zoom chip, its needle up.
    #expect(Pixels.pixel(topRight, at: CGPoint(x: 368, y: 32))?.isNear(Self.ink) == true)
    #expect(Pixels.pixel(topRight, at: CGPoint(x: 368, y: 120.5))?.isNear(Self.needle) == true)
    #expect(
      Pixels.pixel(topRight, at: CGPoint(x: 32, y: 32))?.isNear(Controls.color("#000000")) == true)
    // Bottom left: the same stack, read from the top, in the other corner.
    #expect(Pixels.pixel(bottomLeft, at: CGPoint(x: 32, y: 272))?.isNear(Self.ink) == true)
    #expect(Pixels.pixel(bottomLeft, at: CGPoint(x: 32, y: 360.5))?.isNear(Self.needle) == true)
  }

  @Test("a flag left out takes its fixed default, and nothing is read from the organization")
  func defaults() throws {
    let map = try Maps.engine()
    let unstated = try #require(Controls.drawn(Self.laid(MapControls(map))))
    let stated = try #require(
      Controls.drawn(
        Self.laid(
          MapControls(
            map, zoom: true, compass: true, geolocate: false, layers: true, pois: false,
            preferences: true, offersTime: false))))
    let none = try #require(
      Controls.drawn(
        Self.laid(
          MapControls(map, zoom: false, compass: false, layers: false, preferences: false))))

    #expect(unstated.pngData() == stated.pngData())
    #expect(unstated.pngData() != none.pngData())
  }

  @Test("the app's own controls stand between the panel toggles and geolocate")
  func content() throws {
    let map = try Maps.engine()
    let image = try #require(
      Controls.drawn(
        Self.laid(
          MapControls(
            map, zoom: false, compass: false, geolocate: true, layers: false, preferences: false
          ) {
            Color(red: 1, green: 0, blue: 0).frame(width: 44, height: 44)
          })))

    // The app's own control first, the locate control 8 points under it.
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 368, y: 32))?.isNear(Controls.color("#ff0000")) == true)
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 352, y: 66))?.isNear(Controls.color("#ffffff")) == true)
  }

  /// Asked records each picture a layers panel asks the app for. It is no `Held`: a panel asks as
  /// it draws, and a change SwiftUI observes there would draw the panel again, and so forever.
  @MainActor
  private final class Asked {
    var pictures: [String] = []
  }

  @Test("the stack's layers panel offers the time and shows the pictures the app hands the stack")
  func layersPanel() async throws {
    let selection = LayersSelectionEngine(map: LayersPanelTests.Answering())
    await settled()
    let asked = Asked()
    let probe = RenderProbe()
    let controls = MapControls(
      nil, layers: true, offersTime: true,
      thumbnail: { choice, slug in
        asked.pictures.append("\(choice.rawValue) \(slug)")
        return nil
      })
    let (host, window) = Hosted.showing(
      controls.layersPanel(over: selection).environment(\.renderProbe, probe))

    #expect(
      await MapWindow.until { probe.counts.keys.contains { $0.hasPrefix("LayersPanelTime ") } },
      "\(probe.counts)")
    #expect(
      await MapWindow.until { asked.pictures.contains("terrain topo") }, "\(asked.pictures)")
    window.isHidden = true
    _ = host
    selection.close()
  }

  @Test("a disabled stack shuts every control under it")
  func disabled() throws {
    let map = try Maps.engine()
    let image = try #require(
      Controls.drawn(
        Self.laid(
          MapControls(map, zoom: true, compass: false, layers: false, preferences: false)
            .disabled(true))))

    #expect(
      Pixels.pixel(image, at: CGPoint(x: 368, y: 32))?.isNear(Controls.color("#adb5bd")) == true)
  }

  @Test("in a layout that runs right to left, the mark stands top left and the stack top right")
  func rightToLeft() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          WatermarkLink(engine: map)
          MapControls(map, zoom: true, compass: false, layers: false, preferences: false)
        }
        .frame(width: 400, height: 400)
        .environment(\.layoutDirection, .rightToLeft)))

    // The wordmark, white at the drawing's opacity, in the top-left corner the reader sees.
    let light = (40..<140).contains { x in
      guard let pixel = Pixels.pixel(image, at: CGPoint(x: x, y: 31)) else { return false }
      return pixel.red > 160 && pixel.green > 160 && pixel.blue > 160
    }
    #expect(map.isWatermarked)
    #expect(light, "the mark stands top left")
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 368, y: 32))?.isNear(Self.ink) == true,
      "the stack top right, where the reader sees that corner")
    #expect(
      StackPlacement.stackPadding(
        corner: .topRight, space: CGSize(width: 400, height: 400),
        room: CGRect(x: 0, y: 0, width: 400, height: 400), stack: CGSize(width: 44, height: 88),
        clearOf: CGRect(x: -4, y: -4, width: 180, height: 75.5))
        == PixelPadding(top: 10, right: 10, bottom: 0, left: 0),
      "clear of the frame, which it does not reach")
  }

  @Test(
    "a stack given no map keeps to its space's safe area and holds the frame a waiting read does"
  )
  func noMap() {
    let space = CGRect(x: 0, y: 0, width: 390, height: 844)
    let insets = PixelPadding(top: 59, right: 0, bottom: 34, left: 0)
    #expect(StackPlacement.holdsFrame(nil), "a stack given no map holds it as a waiting read does")
    let kept = StackPlacement.keptClear(of: nil, holdsFrame: true, space: space, safeArea: insets)
    #expect(
      StackPlacement.mapRect(nil, in: space) == CGRect(x: 0, y: 0, width: 390, height: 844),
      "with no map drawn, the space's edge cuts its panels")
    #expect(kept.room == CGRect(x: 0, y: 59, width: 390, height: 751))
    let frame = kept.frame
    #expect(frame?.minX == -4 && frame?.minY == 55 && frame?.width == 180)
    let topLeft = StackPlacement.stackPadding(
      corner: .topLeft, space: space.size, room: kept.room, stack: CGSize(width: 44, height: 88),
      clearOf: kept.frame)
    #expect(
      abs(topLeft.top - (55 + watermarkHeight + 10)) < 1e-9,
      "below the frame, as far from it as from the edges")
    #expect(topLeft.left == 10)

    let drawnNowhere = try? Maps.engine()
    #expect(StackPlacement.shown(drawnNowhere) == nil, "a map no view draws reads as none")
  }

  @Test(
    "over a map no view draws, a stack keeps to its space's safe area and holds the frame as the map's read does"
  )
  func mapNoViewDraws() async throws {
    let space = CGRect(x: 0, y: 0, width: 390, height: 844)
    let insets = PixelPadding(top: 59, right: 0, bottom: 34, left: 0)
    let waiting = try Maps.engine()
    #expect(StackPlacement.shown(waiting) == nil, "no view draws it yet")
    #expect(StackPlacement.holdsFrame(waiting), "held while its read waits, as once it is drawn")
    let held = StackPlacement.keptClear(
      of: StackPlacement.shown(waiting), holdsFrame: StackPlacement.holdsFrame(waiting),
      space: space, safeArea: insets)
    #expect(held.room == CGRect(x: 0, y: 59, width: 390, height: 751), "the space's own safe area")
    #expect(held.frame == CGRect(x: -4, y: 55, width: 180, height: watermarkHeight))

    let whiteLabel = try Maps.whiteLabel()
    _ = try await whiteLabel.loadOrganization()
    #expect(whiteLabel.organizationRead == .answered(whiteLabel: true))
    #expect(!StackPlacement.holdsFrame(whiteLabel), "an answer of white label releases it")
    let released = StackPlacement.keptClear(
      of: StackPlacement.shown(whiteLabel), holdsFrame: StackPlacement.holdsFrame(whiteLabel),
      space: space, safeArea: insets)
    #expect(released.room == held.room)
    #expect(released.frame == nil, "nothing to keep clear of where no mark will be drawn")
    #expect(
      StackPlacement.stackPadding(
        corner: .topLeft, space: space.size, room: released.room,
        stack: CGSize(width: 44, height: 88), clearOf: released.frame)
        == PixelPadding(top: 69, right: 0, bottom: 0, left: 10),
      "a stack in the top-left corner stands in its corner, as it will once the map is drawn")

    // Once a view draws the map, the stack reads the map's own frame, held as it was.
    waiting.shown(at: ScreenRect(x: 0, y: 0, width: 390, height: 844))
    waiting.safeAreaShown(insets)
    let drawn = StackPlacement.keptClear(
      of: StackPlacement.shown(waiting), holdsFrame: StackPlacement.holdsFrame(waiting),
      space: space, safeArea: insets)
    #expect(drawn.room == held.room && drawn.frame == held.frame, "nothing moves as it appears")
  }

  @Test("over a space larger than its map, a stack keeps to the map's own safe area and frame")
  func mapBelowAHeader() throws {
    let map = try Maps.engine()
    // The map stands under a header 120 points tall, the stack laid over the whole window.
    map.shown(at: ScreenRect(x: 0, y: 120, width: 390, height: 724))
    map.safeAreaShown(PixelPadding(top: 0, right: 0, bottom: 34, left: 0))
    let space = CGRect(x: 0, y: 0, width: 390, height: 844)
    let kept = StackPlacement.keptClear(
      of: StackPlacement.shown(map), holdsFrame: StackPlacement.holdsFrame(map), space: space,
      safeArea: PixelPadding(top: 59, right: 0, bottom: 34, left: 0))
    #expect(
      StackPlacement.mapRect(map.shownMap, in: space)
        == CGRect(x: 0, y: 120, width: 390, height: 724),
      "the map's own edge cuts its panels, not the space's")
    #expect(kept.room == CGRect(x: 0, y: 120, width: 390, height: 690), "the map's safe area")
    #expect(
      kept.frame == CGRect(x: -4, y: 116, width: 180, height: watermarkHeight),
      "the map's own frame")
    let topLeft = StackPlacement.stackPadding(
      corner: .topLeft, space: space.size, room: kept.room, stack: CGSize(width: 44, height: 88),
      clearOf: kept.frame)
    #expect(abs(topLeft.top - (116 + watermarkHeight + 10)) < 1e-9 && topLeft.left == 10)
  }

  @Test(
    "a stack keeps to the safe area in any corner, and clear of the watermark's frame by the smallest move"
  )
  func clearOfTheMark() {
    let mark = CGRect(x: -4, y: 55, width: 180, height: 75.5)
    let space = CGSize(width: 390, height: 844)
    let safe = CGRect(x: 0, y: 59, width: 390, height: 751)
    let stack = CGSize(width: 44, height: 200)
    func padding(_ corner: MapCorner, room: CGRect = safe, clearOf frame: CGRect? = mark)
      -> PixelPadding
    {
      StackPlacement.stackPadding(
        corner: corner, space: space, room: room, stack: stack, clearOf: frame)
    }
    #expect(padding(.topLeft).top == 55 + 75.5 + 10, "as far from the frame as from the edges")
    #expect(padding(.topLeft).left == 10)
    #expect(padding(.topRight) == PixelPadding(top: 69, right: 10, bottom: 0, left: 0))
    #expect(padding(.bottomRight) == PixelPadding(top: 0, right: 10, bottom: 34 + 10, left: 0))
    #expect(padding(.bottomLeft).bottom == 34 + 10, "far from the frame, it stands in its corner")
    #expect(padding(.topLeft, clearOf: nil).top == 69, "a white label map leaves it in its corner")

    let short = CGRect(x: 0, y: 0, width: 390, height: 220)
    let low = StackPlacement.stackPadding(
      corner: .bottomLeft, space: CGSize(width: 390, height: 220), room: short, stack: stack,
      clearOf: mark)
    #expect(low.left == mark.maxX + 10, "a short map moves it beside the frame")
    #expect(
      StackPlacement.stackPadding(
        corner: .topLeft, space: .zero, room: .zero, stack: .zero, clearOf: mark)
        == PixelPadding(10), "a space not laid out yet leaves it in its corner")
  }

  @Test(
    "a panel opens beside its toggle, inside the safe area, and clear of the watermark's frame"
  )
  func panelBeside() {
    let room = CGRect(x: 0, y: 0, width: 1024, height: 700)
    let toggle = CGRect(x: 970, y: 110, width: 44, height: 44)
    let beside = StackPlacement.panelFrame(
      beside: toggle, within: room, height: nil, clearOf: nil)
    #expect(beside.minX == 970 - 8 - 340 && beside.minY == 110 && beside.width == 340)
    #expect(beside.height == 700 - 110, "laid out from the toggle's top in the map")

    let safe = CGRect(x: 0, y: 59, width: 390, height: 751)
    let mark = CGRect(x: -4, y: 55, width: 180, height: 75.5)
    let filled = StackPlacement.panelFrame(
      beside: CGRect(x: 336, y: 100, width: 44, height: 44), within: safe, height: 300,
      clearOf: mark)
    #expect(filled.minX == 10 && filled.width == 370)
    #expect(filled.minY == 55 + 75.5, "its top at the frame's bottom, which it would lay over")
    #expect(filled.maxY <= safe.maxY, "no lower than the safe area")

    let wide = CGRect(x: 0, y: 59, width: 1024, height: 700)
    let below = StackPlacement.panelFrame(
      beside: CGRect(x: 10, y: 69, width: 44, height: 44), within: wide, height: 300,
      clearOf: mark)
    #expect(below.minX == 62 && below.minY == 55 + 75.5, "below the frame, never to its right")
  }
}
