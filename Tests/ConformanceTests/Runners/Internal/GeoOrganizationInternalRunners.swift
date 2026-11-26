import Foundation
import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// organizationWatermark answers the watermark a map draws for the case's `read` of its
  /// organization in its `language`, on its `page` where it states one, or null: its drawing, its
  /// frame, its link and the path of its label. The fixture's drawing, box, frame, links and
  /// origins are held to Geo's.
  static let organizationWatermark = Runner(
    id: "geo.organization.watermark", table: .internal
  ) { fixture, fixtureCase in
    let links = watermarkLinks.map {
      OrderedJSON.Member(key: $0.key.rawValue, value: .string($0.value))
    }
    try fixture.holdConstants(
      ["inset": ElementLayout.watermarkInset, "width": ElementLayout.watermarkWidth],
      values: [
        "drawing": .string(watermarkDrawing),
        "firstPartyOrigins": GeoFixtures.texts(watermarkFirstPartyOrigins),
        "label": .string(watermarkLabelWord),
        "links": .object(links.sorted { $0.key < $1.key }),
        "root": .string(watermarkRoot),
        "viewBox": GeoFixtures.numbers(GlyphDrawing.artwork[watermarkDrawing]?.viewBox ?? []),
      ])
    let input = fixtureCase.input
    let read: OrganizationRead
    switch try input.string(at: "read") {
    case "answered": read = .answered(whiteLabel: try input.flag(at: "whiteLabel"))
    case "waiting": read = .waiting
    case "failed": read = .failed
    case "timed-out": read = .timedOut
    case "no-key": read = .noKey
    case let other: throw FixtureError(description: "no read is `\(other)`")
    }
    var page: (origin: String, topLevel: Bool)?
    if let written = input["page"], !written.isNull {
      page = (try written.string(at: "origin"), try written.flag(at: "topLevel"))
    }
    guard
      let mark = watermarkOf(
        read, language: RestSchema.Language(rawValue: try input.string(at: "language")),
        page: page)
    else { return .value(.null) }
    return .value(
      .object([
        OrderedJSON.Member(key: "drawing", value: .string(mark.drawing)),
        OrderedJSON.Member(
          key: "frame",
          value: .object([
            OrderedJSON.Member(key: "height", value: .number(mark.height)),
            OrderedJSON.Member(key: "width", value: .number(mark.width)),
            OrderedJSON.Member(key: "x", value: .number(mark.x)),
            OrderedJSON.Member(key: "y", value: .number(mark.y)),
          ])),
        OrderedJSON.Member(key: "href", value: .string(mark.href)),
        OrderedJSON.Member(key: "label", value: .string(mark.label)),
      ]))
  }

  /// readoutRows answers the rows the readout opened at the case's point states, each its kind and
  /// what it states, a moment in epoch milliseconds and a word by its path. The tables are held to
  /// Geo's.
  static let readoutRows = Runner(id: "geo.readout.rows", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      ["copyDecimals": Double(readoutCopyDecimals), "detailZoom": readoutDetailZoom],
      values: [
        "overlayReadouts": GeoOrganizationFixtures.overlayReadoutTable(),
        "poiCategories": .object(
          poiTileCategories.sorted { $0.key < $1.key }.map {
            OrderedJSON.Member(key: $0.key, value: .string($0.value.rawValue))
          }),
        "zoneLevelColors": .object(
          zoneLevelColors.sorted { $0.key.rawValue < $1.key.rawValue }.map {
            OrderedJSON.Member(key: $0.key.rawValue, value: .string($0.value))
          }),
        "zoneLevelFallback": .string(zoneLevelFallback.rawValue),
      ])
    let facts = try GeoOrganizationFixtures.facts(fixtureCase.input)
    return .value(
      .object([
        OrderedJSON.Member(
          key: "rows",
          value: .array(MountayaGeo.readoutRows(facts).map(GeoOrganizationFixtures.row)))
      ]))
  }

  /// panelsLayout answers how a panel lays out over the case's map at its top inset. The measures
  /// are held to the tokens table's `layout` as Geo prints it.
  static let panelsLayout = Runner(id: "geo.panels.layout", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "layerCardColumns": Double(ElementLayout.panelLayerCardColumns),
      "narrowBottomInset": ElementLayout.panelNarrowBottomInset,
      "narrowMapWidth": ElementLayout.panelNarrowMapWidth,
      "pictureHeight": ElementLayout.panelPictureHeight,
      "pictureHeightNarrow": ElementLayout.panelPictureHeightNarrow,
      "preferenceCardColumns": Double(ElementLayout.panelPreferenceCardColumns),
      "width": ElementLayout.panelWidth,
    ])
    let input = fixtureCase.input
    let layout = panelLayout(
      mapWidth: try input.number(at: "mapWidth"), mapHeight: try input.number(at: "mapHeight"),
      topInset: try input.number(at: "topInset"))
    return .value(
      .object([
        OrderedJSON.Member(key: "fill", value: .bool(layout.fill)),
        OrderedJSON.Member(key: "maxHeight", value: .number(layout.maxHeight)),
        OrderedJSON.Member(key: "pictureHeight", value: .number(layout.pictureHeight)),
        OrderedJSON.Member(key: "width", value: layout.width.map { .number($0) } ?? .null),
      ]))
  }
}

/// GeoOrganizationFixtures reads the readout's fixtures into Geo's values, and writes Geo's answers
/// back as they expect them.
enum GeoOrganizationFixtures {
  /// overlayReadoutTable writes Geo's table of the overlays a readout states a band of.
  static func overlayReadoutTable() -> OrderedJSON {
    .object(
      overlayReadouts.sorted { $0.key < $1.key }.map { entry in
        var members = [
          OrderedJSON.Member(key: "measure", value: .string(entry.value.measure.rawValue))
        ]
        if let pace = entry.value.pace {
          members.append(OrderedJSON.Member(key: "pace", value: .string(pace.rawValue)))
        }
        if entry.value.scale != 1 {
          members.append(OrderedJSON.Member(key: "scale", value: .number(entry.value.scale)))
        }
        return OrderedJSON.Member(key: entry.key, value: .object(members))
      })
  }

  /// facts reads what a map holds at the readout's point.
  static func facts(_ input: OrderedJSON) throws(FixtureError) -> ReadoutFacts {
    var facts = ReadoutFacts(
      position: try input.numbers(at: "position"), zoom: try input.number(at: "zoom"))
    if let terrain = input["terrain"], !terrain.isNull {
      facts.terrain = TerrainReading(
        elevation: try terrain.number(at: "elevation"),
        slope: try terrain.optionalNumber(at: "slope") ?? .nan,
        aspect: try terrain.optionalNumber(at: "aspect"))
    }
    if let poi = input["poi"], !poi.isNull {
      facts.poi = ReadoutFacts.POI(
        name: try poi.string(at: "name"), category: try poi.string(at: "category"))
    }
    if let zone = input["zone"], !zone.isNull {
      facts.zone = ReadoutFacts.Zone(
        name: try zone.string(at: "name"), description: try zone.string(at: "description"),
        level: RestSchema.ZoneLevel(rawValue: try zone.string(at: "level")),
        startAt: try zone.optionalNumber(at: "startAt"),
        endAt: try zone.optionalNumber(at: "endAt"))
    }
    if let overlay = input["overlay"], !overlay.isNull {
      facts.overlay = ReadoutFacts.Overlay(
        slug: try overlay.string(at: "slug"), name: try overlay.string(at: "name"),
        vector: try overlay.flag(at: "vector"))
    }
    if let band = input["band"], !band.isNull {
      facts.band = (try band.optionalNumber(at: "min"), try band.optionalNumber(at: "max"))
    }
    facts.instant = try input.optionalNumber(at: "instant").map {
      Date(timeIntervalSince1970: $0 / 1000)
    }
    return facts
  }

  /// milliseconds writes an instant in epoch milliseconds, or null.
  private static func milliseconds(_ instant: Date?) -> OrderedJSON {
    instant.map { .number(($0.timeIntervalSince1970 * 1000).rounded()) } ?? .null
  }

  /// text writes a text, or null.
  private static func text(_ value: String?) -> OrderedJSON {
    value.map { .string($0) } ?? .null
  }

  /// row writes a row as the fixture expects it.
  static func row(_ row: ReadoutRow) -> OrderedJSON {
    switch row {
    case .poi(let name, let category, let label):
      return .object([
        OrderedJSON.Member(key: "category", value: text(category?.rawValue)),
        OrderedJSON.Member(key: "label", value: .string(label)),
        OrderedJSON.Member(key: "name", value: text(name)),
        OrderedJSON.Member(key: "row", value: .string("poi")),
      ])
    case .band(let overlay, let measure, let pace, let values, let word, let time):
      return .object([
        OrderedJSON.Member(key: "measure", value: .string(measure.rawValue)),
        OrderedJSON.Member(key: "overlay", value: .string(overlay)),
        OrderedJSON.Member(key: "pace", value: text(pace?.rawValue)),
        OrderedJSON.Member(key: "row", value: .string("band")),
        OrderedJSON.Member(
          key: "time",
          value: time.map {
            .object([
              OrderedJSON.Member(key: "moment", value: milliseconds($0)),
              OrderedJSON.Member(key: "word", value: .string("readout.overlayTime")),
            ])
          } ?? .null),
        OrderedJSON.Member(key: "values", value: GeoFixtures.numbers(values)),
        OrderedJSON.Member(key: "word", value: text(word)),
      ])
    case .terrain(let readings):
      return .object([
        OrderedJSON.Member(key: "readings", value: .array(readings.map(reading))),
        OrderedJSON.Member(key: "row", value: .string("terrain")),
      ])
    case .instant(let instant):
      return .object([
        OrderedJSON.Member(key: "moment", value: milliseconds(instant)),
        OrderedJSON.Member(key: "row", value: .string("instant")),
        OrderedJSON.Member(key: "word", value: .string("readout.overlayTime")),
      ])
    case .coordinates(let written, let copy):
      return .object([
        OrderedJSON.Member(key: "copy", value: .string(copy)),
        OrderedJSON.Member(key: "row", value: .string("coordinates")),
        OrderedJSON.Member(key: "text", value: .string(written)),
        OrderedJSON.Member(key: "word", value: .string("readout.coordinates")),
      ])
    case .zoomIn:
      return .object([
        OrderedJSON.Member(key: "row", value: .string("zoom-in")),
        OrderedJSON.Member(key: "word", value: .string("readout.zoomInForDetails")),
      ])
    case .zone(let name, let description, let level, let levelWord, let color, let window):
      return .object([
        OrderedJSON.Member(key: "color", value: .string(color)),
        OrderedJSON.Member(key: "description", value: text(description)),
        OrderedJSON.Member(key: "level", value: .string(level.rawValue)),
        OrderedJSON.Member(key: "levelWord", value: text(levelWord)),
        OrderedJSON.Member(key: "name", value: text(name)),
        OrderedJSON.Member(key: "row", value: .string("zone")),
        OrderedJSON.Member(
          key: "window",
          value: window.map {
            .object([
              OrderedJSON.Member(key: "end", value: milliseconds($0.end)),
              OrderedJSON.Member(key: "start", value: milliseconds($0.start)),
              OrderedJSON.Member(key: "word", value: .string($0.word)),
            ])
          } ?? .null),
        OrderedJSON.Member(key: "word", value: .string("readout.zone")),
      ])
    }
  }

  /// reading writes one reading of the terrain row.
  private static func reading(_ reading: ReadoutRow.Reading) -> OrderedJSON {
    switch reading {
    case .altitude(let value):
      return .object([
        OrderedJSON.Member(key: "reading", value: .string("altitude")),
        OrderedJSON.Member(key: "value", value: .number(value)),
        OrderedJSON.Member(key: "word", value: .string(reading.word)),
      ])
    case .slope(let value, let color):
      return .object([
        OrderedJSON.Member(key: "color", value: .string(color)),
        OrderedJSON.Member(key: "reading", value: .string("slope")),
        OrderedJSON.Member(key: "value", value: .number(value)),
        OrderedJSON.Member(key: "word", value: .string(reading.word)),
      ])
    case .aspect(let value, let cardinal):
      return .object([
        OrderedJSON.Member(key: "cardinal", value: .string(cardinal.rawValue)),
        OrderedJSON.Member(
          key: "cardinalWord", value: .string("readout.aspects.\(cardinal.rawValue)")),
        OrderedJSON.Member(key: "reading", value: .string("aspect")),
        OrderedJSON.Member(key: "value", value: .number(value)),
        OrderedJSON.Member(key: "word", value: .string(reading.word)),
      ])
    }
  }
}
