import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("featureProperties")
struct FeaturePropertiesTests {
  @Test("a property the datum does not state is null")
  func absent() {
    #expect(numberProperty(nil as Double?) == .null)
    #expect(numberProperty(nil as Int?) == .null)
    #expect(textProperty(nil) == .null)
    #expect(numbersProperty(nil) == .null)
    #expect(numbersProperty([6, 45]) == [6, 45])
    #expect(numberProperty(7) == 7)
    #expect(featureProperties(("a", .null), ("b", .null)) == ["a": .null, "b": .null])
    #expect(featureProperties(("a", 1), ("a", 2)) == ["a": 2])
  }

  @Test("a point is drawn only where it names a place")
  func point() {
    #expect(pointOrNil([6, 45, 1200]) == .point(GeoJSONPoint(coordinates: [6, 45, 1200])))
    #expect(pointOrNil([6]) == nil)
    #expect(pointOrNil([.nan, 45]) == nil)
    #expect(pointOrNil(nil) == nil)
    #expect(
      [featureKindProperty, featureIndexProperty, featureColorProperty, featureWidthProperty]
        == ["mtyaKind", "mtyaIndex", "mtyaColor", "mtyaWidth"])
  }
}
