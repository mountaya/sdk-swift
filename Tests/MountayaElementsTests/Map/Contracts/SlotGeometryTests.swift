import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("SlotGeometry")
struct SlotGeometryTests {
  private static let line = GeoJSONGeometry.lineString(
    GeoJSONLineString(coordinates: [[6.86, 45.83], [6.87, 45.84]]))

  @Test("two slots' holdings are one where the geometry is the same and the colour by its scalars")
  func equality() {
    let held = SlotGeometry(geometry: Self.line, color: "#2b8a3e")

    #expect(held == SlotGeometry(geometry: Self.line, color: "#2b8a3e"))
    #expect(held != SlotGeometry(geometry: nil, color: "#2b8a3e"))
    #expect(held != SlotGeometry(geometry: Self.line, color: "#2B8A3E"))
    #expect(
      held
        != SlotGeometry(
          geometry: .lineString(GeoJSONLineString(coordinates: [[6.86, 45.83], [6.87, 45.85]])),
          color: "#2b8a3e"))
    #expect(
      SlotGeometry(geometry: nil, color: "caf\u{E9}")
        != SlotGeometry(geometry: nil, color: "cafe\u{301}"))
    #expect(
      SlotGeometry(geometry: nil, color: "#f59f00") == SlotGeometry(geometry: nil, color: "#f59f00")
    )
  }
}
