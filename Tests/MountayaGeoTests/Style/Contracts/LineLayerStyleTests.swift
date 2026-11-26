import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LineLayerStyle")
struct LineLayerStyleTests {
  private let style = LineLayerStyle(
    layout: ["line-cap": "round", "line-join": "round"],
    paint: ["line-color": "#123456", "line-width": ["interpolate", ["linear"], ["zoom"], 7, 2]])

  @Test("two styles are equal where their layout and paint hold the same properties")
  func equality() {
    let copy = LineLayerStyle(
      layout: ["line-join": "round", "line-cap": "round"],
      paint: ["line-width": ["interpolate", ["linear"], ["zoom"], 7, 2], "line-color": "#123456"])
    #expect(style == copy)
    #expect(style.hashValue == copy.hashValue)
    #expect(style != LineLayerStyle(layout: [:], paint: style.paint))
    #expect(style != LineLayerStyle(layout: style.layout, paint: ["line-color": "#123456"]))
  }

  @Test("two styles compare their numbers as the same numbers and their texts by scalars")
  func sameJson() {
    let unknown = LineLayerStyle(layout: [:], paint: ["line-opacity": .number(.nan)])
    #expect(unknown == LineLayerStyle(layout: [:], paint: ["line-opacity": .number(.nan)]))
    #expect(
      unknown.hashValue
        == LineLayerStyle(layout: [:], paint: ["line-opacity": .number(.nan)]).hashValue)
    #expect(
      LineLayerStyle(layout: [:], paint: ["line-opacity": 0])
        != LineLayerStyle(layout: [:], paint: ["line-opacity": .number(-0.0)]))
    #expect(
      LineLayerStyle(layout: [:], paint: ["line-color": "caf\u{E9}"])
        != LineLayerStyle(layout: [:], paint: ["line-color": "cafe\u{301}"]))
  }
}
