import Foundation
import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// profileWindowSpans answers the case's `spans` a chart draws under itself over its `window`,
  /// each its place in the list, its two ends in order and where its start and its end are drawn.
  static let profileWindowSpans = Runner(id: "geo.profile.window-spans", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    var spans: [ProfileRange] = []
    for span in try input.array(at: "spans") {
      spans.append(ProfileRange(from: try span.number(at: "from"), to: try span.number(at: "to")))
    }
    let placed = placeSpans(
      spans, totalDistance: try input.number(at: "totalDistance"),
      window: try ProfileJSON.window(input["window"]))
    return .value(
      .array(
        placed.map {
          ProfileJSON.object([
            "end": .number($0.end), "from": .number($0.from), "index": .number(Double($0.index)),
            "start": .number($0.start), "to": .number($0.to),
          ])
        }))
  }

  /// profileStatStrip answers what the stat strip states for the case's `characteristics` and
  /// `cursor`, in the order its `stats` ask. The default figures are held to the published ones.
  static let profileStatStrip = Runner(id: "geo.profile.stat-strip", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:], values: ["defaultStats": GeoFixtures.texts(defaultStatStripStats.map(\.rawValue))])
    let input = fixtureCase.input
    guard let figures = input["characteristics"], figures.members != nil else {
      throw FixtureError(description: "the case's `characteristics` is not an object")
    }
    let characteristics = ResolvedCharacteristics(
      distance: try figures.optionalNumber(at: "distance"),
      duration: try figures.optionalNumber(at: "duration"),
      ascent: try figures.optionalNumber(at: "ascent"),
      descent: try figures.optionalNumber(at: "descent"),
      altitudeMin: try figures.optionalNumber(at: "altitudeMin"),
      altitudeMax: try figures.optionalNumber(at: "altitudeMax"),
      slopeMin: try figures.optionalNumber(at: "slopeMin"),
      slopeMax: try figures.optionalNumber(at: "slopeMax"),
      trailDifficultyMin: try figures.optionalString(at: "trailDifficultyMin").map {
        RestSchema.TrailDifficultyType(rawValue: $0)
      },
      trailDifficultyMax: try figures.optionalString(at: "trailDifficultyMax").map {
        RestSchema.TrailDifficultyType(rawValue: $0)
      })
    var cursor: StatStripCursor?
    if let stands = input["cursor"], !stands.isNull {
      cursor = StatStripCursor(
        distance: try stands.number(at: "distance"), elevation: try stands.number(at: "elevation"),
        grade: try stands.optionalNumber(at: "grade"))
    }
    let cells = statStripCells(
      characteristics, cursor: cursor,
      stats: try ProfileInternalJSON.stats(input, of: StatStripStat.self)
        ?? defaultStatStripStats)
    return .value(
      .array(
        cells.map { cell in
          let value: OrderedJSON =
            if case .difficulty(let difficulty) = cell {
              .string(difficulty.rawValue)
            } else {
              GeoProfileFixtures.number(cell.number)
            }
          return ProfileJSON.object(["key": .string(cell.stat.rawValue), "value": value])
        }))
  }

  /// profileCursorReadout answers what a profile states about the sample at the case's `index`
  /// of its `series`, in the order its `stats` ask, among its classified `stretches`. The default
  /// figures, the noise threshold and the grade window are held to the published ones.
  static let profileCursorReadout = Runner(id: "geo.profile.cursor-readout", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [
        "elevationNoiseThresholdMeters": elevationNoiseThresholdMeters,
        "gradeWindowMeters": gradeWindowMeters,
      ],
      values: ["defaultStats": GeoFixtures.texts(defaultReadoutStats.map(\.rawValue))])
    let input = fixtureCase.input
    let series = try GeoProfileFixtures.series(input["series"])
    let index = try input.integer(at: "index")
    guard series.points.indices.contains(index) else {
      throw FixtureError(description: "the series holds no sample \(index)")
    }
    var stretches: [ProfileClass] = []
    if let listed = input["stretches"], !listed.isNull {
      guard let entries = listed.elements else {
        throw FixtureError(description: "`stretches` is not an array")
      }
      for entry in entries {
        stretches.append(
          ProfileClass(
            from: try entry.number(at: "from"), to: try entry.number(at: "to"),
            color: try entry.string(at: "color"), label: try entry.string(at: "name")))
      }
    }
    let readout = profileReadout(
      series, at: series.points[index],
      stats: try ProfileInternalJSON.stats(input, of: ReadoutStat.self) ?? defaultReadoutStats,
      stretches: stretches)
    return .value(
      ProfileJSON.object([
        "cells": .array(
          readout.cells.map {
            ProfileJSON.object(["key": .string($0.stat.rawValue), "value": .number($0.value)])
          }),
        "grade": GeoProfileFixtures.number(readout.grade),
        "stretch": readout.stretch.map {
          ProfileJSON.object(["color": .string($0.color), "name": .string($0.label)])
        } ?? .null,
      ]))
  }

  /// profileSectionChips answers what a chip states about the case's `leg`, in the order its
  /// `stats` ask. The default figures are held to the published ones.
  static let profileSectionChips = Runner(id: "geo.profile.section-chips", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:], values: ["defaultStats": GeoFixtures.texts(defaultSectionChipStats.map(\.rawValue))])
    let input = fixtureCase.input
    guard let leg = input["leg"], leg.members != nil else {
      throw FixtureError(description: "the case's `leg` is not an object")
    }
    let cells = sectionChipCells(
      ItinerarySegmentRowMetrics(
        sectionDistance: try leg.optionalNumber(at: "sectionDistance"),
        sectionAscent: try leg.optionalNumber(at: "sectionAscent"),
        sectionDescent: try leg.optionalNumber(at: "sectionDescent")),
      stats: try ProfileInternalJSON.stats(input, of: SectionChipStat.self)
        ?? defaultSectionChipStats)
    return .value(
      .array(
        cells.map {
          ProfileJSON.object(["key": .string($0.stat.rawValue), "value": .number($0.value)])
        }))
  }

  /// profileAmenityStacks answers the stacks above the case's pinned `places`, each a pin of its
  /// key whose place offers its `amenities`, capped at its `max` where it states one. The default
  /// maximum is held to the published one.
  static let profileAmenityStacks = Runner(id: "geo.profile.amenity-stacks", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(["defaultMax": defaultAmenityStackMax])
    let input = fixtureCase.input
    var pins: [CurvePin] = []
    for place in try input.array(at: "places") {
      let key = try place.string(at: "key")
      let amenities = try ProfileModelJSON.optionalTexts(place["amenities"]).map {
        RestSchema.WaypointAmenity(rawValue: $0)
      }
      pins.append(
        CurvePin(
          key: key,
          place: ProfilePlace(
            .atDistance(id: key, distance: 0), details: WaypointDetails(amenities: amenities)),
          distance: 0, x: 0, y: 0, altitude: 0))
    }
    let stacks =
      try input.optionalNumber(at: "max").map { amenityStacks(pins, max: $0) }
      ?? amenityStacks(pins)
    return .value(
      .array(
        stacks.map {
          ProfileJSON.object([
            "counted": .number(Double($0.counted)), "key": .string($0.pin.key),
            "named": GeoFixtures.texts($0.named.map(\.rawValue)),
            "shown": GeoFixtures.texts($0.shown.map(\.rawValue)),
          ])
        }))
  }

  /// profileSegmentTableCells answers what the case's `columns` state about its `row`. The default
  /// columns are held to the published ones.
  static let profileSegmentTableCells = Runner(
    id: "geo.profile.segment-table-cells", table: .internal
  ) { fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: ["defaultColumns": GeoFixtures.texts(defaultSegmentTableColumns.map(\.rawValue))])
    let input = fixtureCase.input
    let row = try ProfileModelJSON.segmentRow(input["row"])
    let columns =
      try ProfileInternalJSON.stats(input, at: "columns", of: SegmentTableColumn.self)
      ?? defaultSegmentTableColumns
    return .value(
      .array(
        columns.map { column in
          let cell = segmentRowCell(row, column: column)
          let name = OrderedJSON.Member(key: "column", value: .string(cell.column.rawValue))
          switch cell {
          case .segment(let text):
            return .object([name, OrderedJSON.Member(key: "name", value: .string(text))])
          case .profile(let lit, let color):
            return .object([
              name, OrderedJSON.Member(key: "color", value: GeoProfileFixtures.text(color)),
              OrderedJSON.Member(
                key: "lit",
                value: ProfileJSON.object(["from": .number(lit.from), "to": .number(lit.to)])),
            ])
          case .distance(let leg, let total):
            return .object([
              name, OrderedJSON.Member(key: "leg", value: GeoProfileFixtures.number(leg)),
              OrderedJSON.Member(key: "total", value: GeoProfileFixtures.number(total)),
            ])
          case .elevation(let ascent, let descent, let totalAscent):
            return .object([
              name, OrderedJSON.Member(key: "ascent", value: GeoProfileFixtures.number(ascent)),
              OrderedJSON.Member(key: "descent", value: GeoProfileFixtures.number(descent)),
              OrderedJSON.Member(key: "totalAscent", value: GeoProfileFixtures.number(totalAscent)),
            ])
          case .altitude(let band, let single):
            return .object([
              name,
              OrderedJSON.Member(
                key: "band",
                value: band.map {
                  ProfileJSON.object(["max": .number($0.max), "min": .number($0.min)])
                } ?? .null),
              OrderedJSON.Member(key: "single", value: GeoProfileFixtures.number(single)),
            ])
          case .duration(let seconds):
            return .object([
              name, OrderedJSON.Member(key: "seconds", value: GeoProfileFixtures.number(seconds)),
            ])
          case .difficulty(let text):
            return .object([
              name, OrderedJSON.Member(key: "text", value: GeoProfileFixtures.text(text?.rawValue)),
            ])
          }
        }))
  }

  /// profileWaypointTableCells answers what the case's `columns` state about its `row`, over a set
  /// holding the glyphs it names `held`, for its `units`, a cut-off written as its `cutoffMoment`
  /// where it states one. The default columns and the fallback glyph are held to the published
  /// ones.
  static let profileWaypointTableCells = Runner(
    id: "geo.profile.waypoint-table-cells", table: .internal
  ) { fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "defaultColumns": GeoFixtures.texts(defaultWaypointTableColumns.map(\.rawValue)),
        "fallbackGlyph": .string(waypointFallbackGlyph),
      ])
    let input = fixtureCase.input
    let row = try ProfileModelJSON.waypointRow(input["row"])
    var markup: [String: String] = [:]
    for glyph in try ProfileModelJSON.texts(input["held"] ?? .array([])) {
      markup[glyph] = "<path d=\"M0 0h1\"/>"
    }
    guard let glyphs = GlyphSet(name: fixtureCase.name, paint: .stroke, markup: markup) else {
      throw FixtureError(description: "the case's set cannot be built")
    }
    let units = try ProfileModelJSON.units(input["units"])
    let formatter = try ProfileModelJSON.formatter(input, at: "cutoffMoment")
    let columns =
      try ProfileInternalJSON.stats(input, at: "columns", of: WaypointTableColumn.self)
      ?? defaultWaypointTableColumns
    return .value(
      .array(
        columns.map { column in
          let cell = waypointRowCell(
            row, column: column, glyphs: glyphs, units: units, formatCutoffAt: formatter)
          let name = OrderedJSON.Member(key: "column", value: .string(cell.column.rawValue))
          switch cell {
          case .waypoint(let glyph, let place):
            let label =
              place.map { ProfileJSON.object(["name": .string($0)]) }
              ?? ProfileJSON.object(["word": .string("profile.unlabelledWaypoint")])
            return .object([
              name, OrderedJSON.Member(key: "glyph", value: .string(glyph)),
              OrderedJSON.Member(key: "label", value: label),
            ])
          case .profile(let lit):
            return .object([
              name,
              OrderedJSON.Member(
                key: "lit",
                value: ProfileJSON.object(["from": .number(lit.from), "to": .number(lit.to)])),
            ])
          case .distance(let total):
            return .object([name, OrderedJSON.Member(key: "total", value: .number(total))])
          case .elevation(let ascent, let descent):
            return .object([
              name, OrderedJSON.Member(key: "ascent", value: GeoProfileFixtures.number(ascent)),
              OrderedJSON.Member(key: "descent", value: GeoProfileFixtures.number(descent)),
            ])
          case .altitude(let altitude):
            return .object([
              name, OrderedJSON.Member(key: "altitude", value: GeoProfileFixtures.number(altitude)),
            ])
          case .amenities(let services):
            return .object([
              name,
              OrderedJSON.Member(
                key: "services", value: GeoFixtures.texts(services.map(\.rawValue))),
            ])
          case .cutoff(let moment):
            return .object([
              name, OrderedJSON.Member(key: "moment", value: GeoProfileFixtures.text(moment)),
            ])
          case .properties(let fields):
            return .object([
              name,
              OrderedJSON.Member(
                key: "fields",
                value: .array(
                  fields.map {
                    ProfileJSON.object([
                      "key": .string($0.key), "label": .string($0.label),
                      "value": .string($0.value),
                    ])
                  })),
            ])
          }
        }))
  }

  /// profileAmenityFilter answers the chips a table of the case's `places` offers in its reader's
  /// `language`, the choice after a press of its `press` where it states one, and the rows that
  /// stay by their place in `places`.
  static let profileAmenityFilter = Runner(id: "geo.profile.amenity-filter", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    let language = RestSchema.Language(rawValue: try input.string(at: "language"))
    let scope = scopeOf(.standard, stating: ElementsScopeStatement(language: language))
    var rows: [ItineraryWaypointRow] = []
    for (index, services) in try input.array(at: "places").enumerated() {
      let amenities = try ProfileModelJSON.texts(services).map {
        RestSchema.WaypointAmenity(rawValue: $0)
      }
      rows.append(
        ItineraryWaypointRow(
          key: "row#\(index)",
          place: ProfilePlace(
            .atDistance(id: "row", distance: Double(index)),
            details: WaypointDetails(amenities: amenities)),
          index: index, from: 0, to: Double(index),
          metrics: ItineraryWaypointRowMetrics(distance: Double(index))))
    }
    var picked = try ProfileModelJSON.texts(input["picked"] ?? .array([])).map {
      RestSchema.WaypointAmenity(rawValue: $0)
    }
    if let press = try input.optionalString(at: "press") {
      picked = toggleAmenity(RestSchema.WaypointAmenity(rawValue: press), in: picked)
    }
    let filter = amenityFilter(rows, picked: picked, scope: scope)
    return .value(
      ProfileJSON.object([
        "chips": GeoFixtures.texts(filter.available.map(\.rawValue)),
        "picked": GeoFixtures.texts(picked.map(\.rawValue)),
        "rows": GeoFixtures.numbers(filter.shown.map { Double($0.index) }),
      ]))
  }

  /// profileRowMatch answers the id of the row of the case's `rows` that answers to its `id`, or
  /// that its `distance` stands in, or null.
  static let profileRowMatch = Runner(id: "geo.profile.row-match", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    var rows: [ItinerarySegmentRow] = []
    for (index, row) in try input.array(at: "rows").enumerated() {
      let id = try row.string(at: "id")
      rows.append(
        ItinerarySegmentRow(
          key: id, id: id, memberIds: try ProfileModelJSON.optionalTexts(row["memberIds"]),
          name: "", index: index, from: try row.number(at: "from"), to: try row.number(at: "to"),
          metrics: ItinerarySegmentRowMetrics()))
    }
    if input["distance"] != nil {
      return .value(
        GeoProfileFixtures.text(rowAt(rows, distance: try input.number(at: "distance"))?.id))
    }
    let id = try input.optionalString(at: "id")
    return .value(GeoProfileFixtures.text(rows.first { rowStandsFor($0, id: id) }?.id))
  }
}

/// ProfileInternalJSON reads the lists of figures and columns the element model fixtures ask for.
enum ProfileInternalJSON {
  /// stats reads the case's list under `key`, each a raw value of `Figure`, nil where the case
  /// states none, so the rule's default stands.
  static func stats<Figure: RawRepresentable>(
    _ input: OrderedJSON, at key: String = "stats", of: Figure.Type
  ) throws(FixtureError) -> [Figure]? where Figure.RawValue == String {
    guard let listed = input[key], !listed.isNull else { return nil }
    var figures: [Figure] = []
    for name in try ProfileModelJSON.texts(listed) {
      guard let figure = Figure(rawValue: name) else {
        throw FixtureError(description: "`\(name)` is no \(Figure.self)")
      }
      figures.append(figure)
    }
    return figures
  }
}
