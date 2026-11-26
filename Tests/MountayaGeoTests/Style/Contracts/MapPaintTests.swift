import Testing

@testable import MountayaGeo

@Suite("MapPaint")
struct MapPaintTests {
  private let standard = MapPaint.standard

  @Test("the standard paint is the paint the contract ships")
  func shipped() {
    let itinerary = standard.itinerary
    #expect(itinerary.casingColor == "#ffffff")
    #expect(itinerary.casingOpacity == 0.9)
    #expect(itinerary.casingWidthStops == [7, 4, 10, 4, 13, 5, 16, 7])
    #expect(itinerary.dashArray == [2, 2])
    #expect(itinerary.dashedOpacity == 0.6)
    #expect(itinerary.lineWidthStops == [7, 2, 10, 2, 13, 3, 16, 5])
  }

  /// The ranks and the segments' colours are the values the rank and colour rules read, never a
  /// second copy of them.
  @Test("the standard ranks and segment colours are the ones the rules publish")
  func published() {
    #expect(standard.layerRanks == tileSourceLayerRanks)
    #expect(standard.layerRanks.count == 11)
    #expect(standard.segments.defaultColor == defaultSegmentColor)
    #expect(standard.segments.palette == livelyPalette)
  }

  @Test("the standard casing is wider than the line at every stop, and stops at the same zooms")
  func casingWider() throws {
    let line = standard.itinerary.lineWidthStops
    let casing = standard.itinerary.casingWidthStops
    try #require(line.count == casing.count)
    for index in stride(from: 0, to: line.count, by: 2) {
      #expect(casing[index] == line[index])
      #expect(casing[index + 1] > line[index + 1])
    }
  }

  @Test("a member set on a copy changes that member alone, and the standard paint stands")
  func memberSet() {
    var paint = standard
    paint.itinerary.casingColor = "#1b1b1b"
    #expect(paint.itinerary.casingColor == "#1b1b1b")
    #expect(paint.itinerary.casingOpacity == 0.9)
    #expect(paint.itinerary.casingWidthStops == standard.itinerary.casingWidthStops)
    #expect(paint.itinerary.dashArray == standard.itinerary.dashArray)
    #expect(paint.itinerary.dashedOpacity == standard.itinerary.dashedOpacity)
    #expect(paint.itinerary.lineWidthStops == standard.itinerary.lineWidthStops)
    #expect(paint.layerRanks == standard.layerRanks)
    #expect(paint.segments == standard.segments)
    #expect(MapPaint.standard.itinerary.casingColor == "#ffffff")
    #expect(paint != standard)
  }

  /// A table merged position by position would keep the shipped tail behind a shorter one: `[7, 3]`
  /// would draw 3 pixels at zoom 7 and the shipped widths above it.
  @Test("a list set replaces the shipped one whole")
  func listReplaced() {
    var paint = standard
    paint.itinerary.lineWidthStops = [7, 3]
    paint.segments.palette = ["#0b7285", "#e8590c"]
    #expect(paint.itinerary.lineWidthStops == [7, 3])
    #expect(paint.segments.palette == ["#0b7285", "#e8590c"])
    #expect(paint.segments.defaultColor == defaultSegmentColor)
  }

  @Test("a band added keeps every shipped band, and a band moved keeps the others")
  func bands() {
    var added = standard
    added.layerRanks["acme_avalanche"] = LayerRank.zone.rank
    #expect(added.layerRanks.count == standard.layerRanks.count + 1)
    #expect(added.layerRanks["acme_avalanche"] == 40)
    #expect(added.layerRanks["itinerary_lines"] == 50)

    var moved = standard
    moved.layerRanks["poi_food"] = 85
    #expect(moved.layerRanks["poi_food"] == 85)
    #expect(moved.layerRanks["poi_tourism"] == 80)
    #expect(moved.layerRanks.count == standard.layerRanks.count)
  }

  @Test("a band named after a prototype member is left out, however the table is set")
  func prototypeMembers() {
    var paint = MapPaint.standard
    paint.layerRanks["__proto__"] = 10
    paint.layerRanks["acme_avalanche"] = 45
    paint.layerRanks["constructor"] = 20
    paint.layerRanks["prototype"] = 30

    var expected = tileSourceLayerRanks
    expected["acme_avalanche"] = 45
    #expect(paint.layerRanks == expected)

    paint.layerRanks = ["prototype": 1, "constructor": 2, "__proto__": 3, "acme_ski": 4]
    #expect(paint.layerRanks == ["acme_ski": 4])

    // A name that only holds one of the three, or spells it in another case, is a band.
    paint.layerRanks = ["prototypes": 1, "Constructor": 2, "__proto": 3]
    #expect(paint.layerRanks.count == 3)
  }

  @Test("a patch at two depths sets each member it names")
  func twoDepths() {
    var paint = standard
    paint.itinerary.casingOpacity = 1
    paint.itinerary.dashArray = [1, 3]
    paint.segments.defaultColor = "#495057"
    #expect(paint.itinerary.casingOpacity == 1)
    #expect(paint.itinerary.dashArray == [1, 3])
    #expect(paint.itinerary.casingColor == "#ffffff")
    #expect(paint.segments.defaultColor == "#495057")
    #expect(paint.segments.palette == livelyPalette)
  }

  @Test("two paints are equal where every member holds the same values")
  func equality() {
    var copy = standard
    #expect(copy == standard)
    copy.itinerary.dashedOpacity = 0.5
    #expect(copy != standard)
    copy = standard
    copy.segments.palette.removeLast()
    #expect(copy != standard)
    copy = standard
    copy.layerRanks["fills"] = 41
    #expect(copy != standard)
    copy = standard
    copy.layerRanks["fills"] = nil
    #expect(copy != standard)
  }

  @Test("two paints compare their numbers as the same numbers")
  func sameNumbers() {
    var unknown = standard
    unknown.itinerary.casingOpacity = .nan
    var also = standard
    also.itinerary.casingOpacity = .nan
    #expect(unknown == also)
    var zero = standard
    zero.itinerary.lineWidthStops = [0, 2]
    var negativeZero = standard
    negativeZero.itinerary.lineWidthStops = [-0.0, 2]
    #expect(zero != negativeZero)
    #expect(zero.itinerary != negativeZero.itinerary)
  }

  /// Swift's `String` equality is canonical equivalence: `é` and `e` with a combining acute are one
  /// text there, and two texts here.
  @Test("two paints compare their texts and their source layers by scalars")
  func scalars() {
    var composed = standard
    composed.itinerary.casingColor = "caf\u{E9}"
    var decomposed = standard
    decomposed.itinerary.casingColor = "cafe\u{301}"
    #expect(composed != decomposed)

    var palette = standard
    palette.segments.palette = ["caf\u{E9}"]
    var otherPalette = standard
    otherPalette.segments.palette = ["cafe\u{301}"]
    #expect(palette.segments != otherPalette.segments)

    var band = standard
    band.layerRanks["caf\u{E9}"] = 52
    var otherBand = standard
    otherBand.layerRanks["cafe\u{301}"] = 52
    #expect(band != otherBand)
    var sameBand = standard
    sameBand.layerRanks["caf\u{E9}"] = 52
    #expect(band == sameBand)
  }
}
