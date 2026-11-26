import Testing

@testable import MountayaGeo

@Suite("cullCrowdedLabels")
struct CullCrowdedLabelsTests {
  private func box(_ key: String, left: Double, right: Double) -> AxisLabelBox {
    AxisLabelBox(key: key, left: left, right: right)
  }

  @Test("the gutter is eight")
  func gutter() {
    #expect(axisLabelGutter == 8)
  }

  @Test("every label clear of its neighbours is drawn; the first and last whatever they overlap")
  func clear() {
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 200, right: 260),
        box("c", left: 400, right: 460),
      ]).isEmpty)
    #expect(
      cullCrowdedLabels([box("start", left: 0, right: 60), box("finish", left: 10, right: 70)])
        .isEmpty)
    #expect(cullCrowdedLabels([box("only", left: 0, right: 60)]).isEmpty)
    #expect(cullCrowdedLabels([]).isEmpty)
  }

  @Test("a label meeting the last, or the one drawn before it, is left out")
  func crowded() {
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 100, right: 160),
        box("end", left: 150, right: 210),
      ]) == ["b"])
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 50, right: 110),
        box("c", left: 200, right: 260), box("end", left: 400, right: 460),
      ])
        == ["b"])
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 50, right: 110),
        box("c", left: 68, right: 128), box("end", left: 400, right: 460),
      ])
        == ["b"])
  }

  @Test("a label exactly a gutter away is drawn, a pixel short of it is not")
  func gutterEdge() {
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 68, right: 128),
        box("end", left: 136, right: 196),
      ]).isEmpty)
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 67, right: 127),
        box("end", left: 400, right: 460),
      ]) == ["b"])
  }

  @Test("both ends of a loop are drawn and their duplicates left out, a key stated once")
  func loop() {
    #expect(
      cullCrowdedLabels([
        box("start#0", left: 0, right: 60), box("finish#0", left: 0, right: 60),
        box("finish#1", left: 900, right: 960),
        box("start#1", left: 900, right: 960),
      ]) == ["finish#0", "finish#1"])
    #expect(
      cullCrowdedLabels([
        box("a", left: 0, right: 60), box("b", left: 1, right: 2), box("b", left: 3, right: 4),
        box("z", left: 9, right: 10),
      ]) == ["b"]
    )
  }
}
