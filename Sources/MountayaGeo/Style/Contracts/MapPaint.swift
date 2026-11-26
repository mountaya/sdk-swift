/// MapPaint is how a map paints what it draws above its base map: an itinerary's stroke and the
/// casing beneath it (`geo.style.itinerary-stroke`), the rank each tile source layer draws at
/// (`geo.layers.order`), and the colours a segment is drawn in (`geo.style.segment-colors`).
///
/// A consumer restyles a map by setting the members it changes on a copy of `standard`, which is
/// the paint as the contract ships it (`geo.style.map-paint`): `paint.itinerary.casingColor =
/// "#1b1b1b"` changes the casing's colour and leaves every other value as shipped, a list
/// assigned, `paint.segments.palette = ["#0b7285", "#e8590c"]`, replaces the shipped one whole,
/// and `paint.layerRanks["acme_avalanche"] = 40` adds a band and keeps every shipped one. A colour
/// is a literal MapLibre parses, a hex value, `rgb()` or a named colour, since a renderer's paint
/// takes the colour itself, and a width is in pixels.
///
/// Two are equal where they hold the same values, a text by its scalars and each number as the
/// same number, `NaN` the same as `NaN` and 0 another than -0, as every Geo value compares.
public struct MapPaint: Sendable, Equatable {
  /// Itinerary is the paint of an itinerary's stroke and of the casing beneath it, the one group
  /// `itineraryStrokeStyle(_:paint:)` reads for every stroke, so an itinerary drawn from data, a
  /// directions answer and a draft are stroked alike.
  public struct Itinerary: Sendable, Equatable {
    /// casingColor is the colour of the casing beneath the stroke, which keeps a line legible over
    /// relief.
    public var casingColor: String
    /// casingOpacity is the opacity the casing paints at, from 0 to 1.
    public var casingOpacity: Double
    /// casingWidthStops is the casing's width table, a flat list of zoom and width pairs
    /// interpolated linearly on zoom, wider than the stroke's at every stop as shipped.
    public var casingWidthStops: [Double]
    /// dashArray is the dash a provisional stroke paints in, its lengths alternately drawn and
    /// skipped, in line widths.
    public var dashArray: [Double]
    /// dashedOpacity is the opacity a provisional stroke paints at, from 0 to 1, so it reads as
    /// secondary beside a solid one.
    public var dashedOpacity: Double
    /// lineWidthStops is the stroke's width table, a flat list of zoom and width pairs interpolated
    /// linearly on zoom.
    public var lineWidthStops: [Double]

    /// Two are equal where they hold the same colour by its scalars and the same numbers.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.casingColor, rhs.casingColor) && sameNumber(lhs.casingOpacity, rhs.casingOpacity)
        && sameNumbers(lhs.casingWidthStops, rhs.casingWidthStops)
        && sameNumbers(lhs.dashArray, rhs.dashArray)
        && sameNumber(lhs.dashedOpacity, rhs.dashedOpacity)
        && sameNumbers(lhs.lineWidthStops, rhs.lineWidthStops)
    }
  }

  /// Segments is the colours a segment is drawn in.
  public struct Segments: Sendable, Equatable {
    /// defaultColor is the colour a segment that carries none of its own is drawn in.
    public var defaultColor: String
    /// palette is the wheel a segment's colour is read from, in order around the hue circle, which
    /// `segmentColorAt(_:palette:)` and `assignDistinctColors(_:reserved:palette:)` take.
    public var palette: [String]

    /// Two are equal where they hold the same colours, each by its scalars, in the same order.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.defaultColor, rhs.defaultColor) && lhs.palette.count == rhs.palette.count
        && zip(lhs.palette, rhs.palette).allSatisfy { sameText($0, $1) }
    }
  }

  /// itinerary is the paint of an itinerary's stroke and of its casing.
  public var itinerary: Itinerary
  /// layerRanks is the rank each tile source layer's layers draw at, by the source layer's name,
  /// the table `tileLayerRank(_:ranks:)` reads: a band added draws a consumer's own tiles where it
  /// says, and a source layer the table does not name draws as an overlay.
  ///
  /// A band named `__proto__`, `constructor` or `prototype` is left out however it is set, as every
  /// SDK's paint leaves out a member of those names (`geo.style.map-paint`).
  public var layerRanks: [String: Int] {
    didSet {
      if layerRanks.keys.contains(where: prototypeKeys.contains) {
        layerRanks = layerRanks.filter { !prototypeKeys.contains($0.key) }
      }
    }
  }
  /// segments is the colours a segment is drawn in.
  public var segments: Segments

  /// standard is the paint as the contract ships it: an itinerary's line 2 pixels wide at zooms 7
  /// and 10, 3 at 13 and 5 at 16, over a white casing 2 pixels wider at every stop at an opacity of
  /// 0.9, a provisional stroke dashed two widths on and two off at 0.6, the ranks of
  /// `tileSourceLayerRanks`, and a segment in `defaultSegmentColor` or a colour of `livelyPalette`.
  public static let standard = MapPaint(
    itinerary: Itinerary(
      casingColor: "#ffffff",
      casingOpacity: 0.9,
      casingWidthStops: [7, 4, 10, 4, 13, 5, 16, 7],
      dashArray: [2, 2],
      dashedOpacity: 0.6,
      lineWidthStops: [7, 2, 10, 2, 13, 3, 16, 5]),
    layerRanks: tileSourceLayerRanks,
    segments: Segments(defaultColor: defaultSegmentColor, palette: livelyPalette))

  /// Two paints are equal where every member holds the same values, the rank tables by their source
  /// layers' scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.itinerary == rhs.itinerary && sameRanks(lhs.layerRanks, rhs.layerRanks)
      && lhs.segments == rhs.segments
  }
}

/// sameRanks tells whether two rank tables hold the same bands: as many, and each source layer of
/// one held by the other under a name of the same scalars, at the same rank.
///
/// A `Dictionary` looks a key up by canonical equivalence, and holds no two keys it calls equal, so
/// the key it finds is the one entry that could match, and its own scalars are held to the name
/// looked for.
private func sameRanks(_ a: [String: Int], _ b: [String: Int]) -> Bool {
  guard a.count == b.count else { return false }
  for (layer, rank) in a {
    guard let index = b.index(forKey: layer), sameText(b[index].key, layer), b[index].value == rank
    else { return false }
  }
  return true
}
