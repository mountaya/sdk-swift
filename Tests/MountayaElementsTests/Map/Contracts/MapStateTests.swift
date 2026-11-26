import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("MapState")
struct MapStateTests {
  private static let camera = CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 0, bearing: 0)

  @Test("a state holds what a map shows, drawing nothing above its base map unless told")
  func holds() {
    let state = MapState(style: nil, camera: Self.camera, labelLanguage: .fr)

    #expect(state.style == nil)
    #expect(state.camera == Self.camera)
    #expect(state.labelLanguage == .fr)
    #expect(state.sources.isEmpty)
    #expect(state.layers.isEmpty)
    #expect(state.zoomBounds == ZoomBounds(minZoom: 0, maxZoom: 25.5), "MapLibre Native's own")
    #expect(!state.isAccessRequired)
    #expect(state.terrain == nil)
    #expect(state.terrainVariant == .light, "light until the app asks for dark")
  }

  @Test("two states are equal where every part is the same")
  func equality() {
    let state = MapState(style: nil, camera: Self.camera, labelLanguage: .fr)
    var moved = state
    moved.camera.zoom = 13
    var relabelled = state
    relabelled.labelLanguage = .de

    var refused = state
    refused.isAccessRequired = true
    var terrain = state
    terrain.terrain = "outdoor"
    var dark = state
    dark.terrainVariant = .dark

    #expect(state == MapState(style: nil, camera: Self.camera, labelLanguage: .fr))
    #expect(state != moved)
    #expect(state != relabelled)
    #expect(state != refused, "a refusal of access standing is part of what a map shows")
    #expect(state != terrain)
    #expect(state != dark)
  }
}
