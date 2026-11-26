import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("HeldAnalysis")
struct HeldAnalysisTests {
  @Test("a held result keeps its input, its answer and its options, read back as their types")
  func holds() {
    let input = DataSchema.IsochronesInput(
      activity: .hikingAndTrail, locations: [[6.86, 45.83]], range: [600], rangeType: .time)
    let held = HeldAnalysis(
      kind: .isochrones, input: input, result: DataSchema.IsochronesResult { $0.isochrones = [] },
      chosen: 0, fit: CameraFit(padding: PixelPadding(12)))

    #expect(held.kind == .isochrones)
    #expect((held.input as? DataSchema.IsochronesInput)?.range == [600])
    #expect((held.result as? DataSchema.IsochronesResult)?.isochrones?.isEmpty == true)
    #expect(held.result as? DataSchema.SuggestionsResult == nil, "a result is of its own kind")
    #expect(held.fit == CameraFit(padding: PixelPadding(12)))
  }

  @Test("a result handed over holds no input")
  func handedOver() {
    let held = HeldAnalysis(
      kind: .places, input: nil, result: DataSchema.GeocodeResult { $0.places = [] }, chosen: 0,
      fit: nil)

    #expect(held.input == nil)
    #expect(held.fit == nil)
  }
}
