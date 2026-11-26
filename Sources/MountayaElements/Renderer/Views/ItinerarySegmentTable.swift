#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// ItinerarySegmentTable is an itinerary's legs as a roadbook: a row per leg in chain order, each
  /// stating, column by column, its name, the whole itinerary's sparkline with its own leg lit, its
  /// length over the running distance, its climb and loss over the running climb, and, as the app
  /// asks, its altitude band, its duration and its difficulty (`geo.profile.segment-rows`,
  /// `geo.profile.segment-table-cells`).
  ///
  /// ```swift
  /// ItinerarySegmentTable(itineraryId: "itin_abc", cache: itineraries, map: map)
  /// ```
  ///
  /// It reads the itinerary as `ItineraryProfile` does, through `cache`, or through `engine`, an
  /// engine of the app's the table shows and never closes, a chain the app states, `legs`,
  /// standing in for the itinerary's own and being its curve. A row a reader points at, a
  /// pointer over it or a tap on it, is lit on `map`'s emphasis slot as its stretch of the series
  /// (`map.profile.emphasis`), with a marker at its end under `markerId` (`map.profile.cursor-marker`),
  /// both taken down as the pointer leaves or the table goes; `onHover` takes that over, handed the
  /// row or nil. A leg the map's own cursor is over lights the row standing for it, a collapsed
  /// group's row standing for each of its members, and `highlighted` lights the row a segment id
  /// names in its place, its own or a member's (`geo.profile.row-match`,
  /// `map.profile.table-rows`); a tap hands the row's id to `onSegmentTap`. `.disabled(true)` draws
  /// the table and drives nothing.
  ///
  /// Its words are the scope's `table` section, each replaced by `strings` where it names the word's
  /// path, its figures written in `units`, and its colours the tokens'.
  public struct ItinerarySegmentTable: View {
    private let reading: ItineraryReading
    private let legs: [ItineraryLeg]?
    private let map: MapEngine?
    private let units: UnitPreferences?
    private let columns: [SegmentTableColumn]
    private let highlighted: String?
    private let emphasisColor: String?
    private let markerId: String
    private let markerColor: String?
    private let strings: [String: String]?
    private let onHover: ((ItinerarySegmentRow?) -> Void)?
    private let onSegmentTap: ((String) -> Void)?
    private let onError: ((any Error) -> Void)?

    /// own is the table's own engine over the app's cache, made as it is first asked, or nil where
    /// it reads through the app's.
    @State private var own: ItineraryResourceEngine?
    @State private var link: MapLink<String>
    @State private var failures: FailureRelay
    /// hovered is the leg the map's own cursor is over, as its hover tells it.
    @State private var hovered: String?
    @ViewScope private var scope: ElementsScope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    /// Creates the table of the itinerary `itineraryId` names on `surface`, read through `cache`,
    /// its chain `legs` where the app states one, its rows lit on `map`, its figures in `units`, its
    /// `columns` in order, the row `highlighted` names lit, the map's emphasis in `emphasisColor`, its
    /// marker under `markerId` in `markerColor`, its words replaced by `strings` where it names
    /// theirs, the row pointed at handed to `onHover` in place of the map, a row's id to
    /// `onSegmentTap`, and each failure to read to `onError`, once.
    public init(
      itineraryId: String?,
      cache: ItineraryResourceCache,
      surface: RestSchema.ReadSurface? = nil,
      legs: [ItineraryLeg]? = nil,
      map: MapEngine? = nil,
      units: UnitPreferences? = nil,
      columns: [SegmentTableColumn] = defaultSegmentTableColumns,
      highlighted: String? = nil,
      emphasisColor: String? = nil,
      markerId: String = segmentTableCursorMarkerId,
      markerColor: String? = nil,
      strings: [String: String]? = nil,
      onHover: ((ItinerarySegmentRow?) -> Void)? = nil,
      onSegmentTap: ((String) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        reading: .cache(cache, itineraryId: itineraryId, surface: surface), legs: legs, map: map,
        units: units, columns: columns, highlighted: highlighted, emphasisColor: emphasisColor,
        markerId: markerId, markerColor: markerColor, strings: strings, onHover: onHover,
        onSegmentTap: onSegmentTap, onError: onError)
    }

    /// Creates the table of the itinerary `engine` reads, an engine of the app's the table shows
    /// and never closes, every other argument as the table of an itinerary read by id takes it.
    public init(
      engine: ItineraryResourceEngine,
      legs: [ItineraryLeg]? = nil,
      map: MapEngine? = nil,
      units: UnitPreferences? = nil,
      columns: [SegmentTableColumn] = defaultSegmentTableColumns,
      highlighted: String? = nil,
      emphasisColor: String? = nil,
      markerId: String = segmentTableCursorMarkerId,
      markerColor: String? = nil,
      strings: [String: String]? = nil,
      onHover: ((ItinerarySegmentRow?) -> Void)? = nil,
      onSegmentTap: ((String) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        reading: .engine(engine), legs: legs, map: map, units: units, columns: columns,
        highlighted: highlighted, emphasisColor: emphasisColor, markerId: markerId,
        markerColor: markerColor, strings: strings, onHover: onHover,
        onSegmentTap: onSegmentTap, onError: onError)
    }

    /// Creates the table of the itinerary `reading` reads.
    ///
    /// Both public initializers call it, and it is kept out of line so an app carries its body once
    /// rather than once in each.
    @inline(never)
    private init(
      reading: ItineraryReading,
      legs: [ItineraryLeg]?,
      map: MapEngine?,
      units: UnitPreferences?,
      columns: [SegmentTableColumn],
      highlighted: String?,
      emphasisColor: String?,
      markerId: String,
      markerColor: String?,
      strings: [String: String]?,
      onHover: ((ItinerarySegmentRow?) -> Void)?,
      onSegmentTap: ((String) -> Void)?,
      onError: ((any Error) -> Void)?
    ) {
      self.reading = reading
      self.legs = legs
      self.map = map
      self.units = units
      self.columns = columns
      self.highlighted = highlighted
      self.emphasisColor = emphasisColor
      self.markerId = markerId
      self.markerColor = markerColor
      self.strings = strings
      self.onHover = onHover
      self.onSegmentTap = onSegmentTap
      self.onError = onError
      _link = State(initialValue: MapLink(markerId: markerId))
      _failures = State(initialValue: FailureRelay())
      _scope = ViewScope(strings: strings)
    }

    /// body is the header and a row per leg, or the empty line.
    public var body: some View {
      let drawing = ItineraryDrawing(resolved: resolved, legs: legs)
      let figures = units ?? UnitPreferences(language: scope.locale)
      let scheme = themeScheme(colorScheme)
      // The handler of the latest drawing is the one a failure reaches.
      let _ = failures.hold(onError)
      VStack(alignment: .leading, spacing: 0) {
        if drawing.rows.isEmpty {
          Text(verbatim: scope.word(isResolving ? "table.loading" : "table.empty"))
            .font(.footnote)
            .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
        } else {
          HStack(spacing: 8) {
            ForEach(columns, id: \.self) { column in
              Text(verbatim: scope.word("table.\(column.rawValue)"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .padding(.vertical, 6)
          .accessibilityAddTraits(.isHeader)
          ForEach(drawing.rows, id: \.key) { row in
            rowView(row, drawing: drawing, units: figures, scheme: scheme)
          }
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: scope.word("table.title")))
      .viewWords(scope, stated: strings)
      .task(id: reading.question) {
        // Made as it is first asked, so a table SwiftUI makes and drops asks nothing, and followed
        // before it is asked, so every failure it shows is handed on.
        let read = reading.read(own, following: failures)
        if read !== own { own = read }
      }
      .task(id: map.map(ObjectIdentifier.init)) {
        // The leg the map's own cursor is over, as its hover tells it, lights that leg's row.
        hovered = nil
        guard let map else { return }
        for await event in map.events() {
          if case .featureHover(_, let features) = event {
            hovered = hoveredLeg(features)
          }
        }
      }
      .onChange(of: isEnabled) {
        if !isEnabled { point(at: nil, drawing: drawing) }
      }
      .onDisappear { point(at: nil, drawing: drawing) }
    }

    /// One leg's row, lit where it is pointed at, where the app highlights it, or, where it
    /// highlights none, where the map's cursor is over its leg (`isSegmentRowLit`).
    private func rowView(
      _ row: ItinerarySegmentRow, drawing: ItineraryDrawing, units figures: UnitPreferences,
      scheme: ThemeScheme
    ) -> some View {
      let isPointed = isSegmentRowLit(
        row, pointed: link.pointed, highlighted: highlighted, hovered: hovered)
      return HStack(spacing: 8) {
        ForEach(columns, id: \.self) { column in
          Self.cell(
            segmentRowCell(row, column: column), series: drawing.series, units: figures,
            scope: scope
          )
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.vertical, 6)
      .frame(minHeight: 44)
      .background(isPointed ? tokenColor(tokens.tableRowHover, in: scheme) : .clear)
      .overlay(alignment: .bottom) {
        tokenColor(tokens.tableBorder, in: scheme).frame(height: 1)
      }
      .contentShape(Rectangle())
      .onContinuousHover { phase in
        switch phase {
        case .active: point(at: row, drawing: drawing)
        case .ended: if link.pointed == row.key { point(at: nil, drawing: drawing) }
        }
      }
      .onTapGesture { tap(row, drawing: drawing) }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(isPointed ? [.isButton, .isSelected] : .isButton)
      .accessibilityAction { tap(row, drawing: drawing) }
    }

    /// A tap on a row, or its activation by an assistive technology: it points at the row, or at
    /// none where it was pointed at, and hands the row's id to `onSegmentTap`.
    private func tap(_ row: ItinerarySegmentRow, drawing: ItineraryDrawing) {
      guard isEnabled else { return }
      point(at: link.pointed == row.key ? nil : row, drawing: drawing)
      onSegmentTap?(row.id)
    }

    /// cell is one cell of a leg's row, as its column states it.
    @ViewBuilder
    static func cell(
      _ cell: SegmentRowCell, series: ElevationSeries, units: UnitPreferences, scope: ElementsScope
    ) -> some View {
      if case .profile(let lit, let color) = cell {
        ItinerarySparkline(series: series, lit: lit, color: color).frame(height: 24)
      } else {
        let lines = text(cell, units: units)
        VStack(alignment: .leading, spacing: 1) {
          if case .segment = cell {
            Text(verbatim: lines.first ?? "").font(.subheadline.weight(.semibold)).lineLimit(2)
          } else {
            Text(verbatim: lines.first ?? "").font(.subheadline).monospacedDigit()
          }
          ForEach(Array(lines.dropFirst().enumerated()), id: \.offset) { _, total in
            Text(verbatim: total).font(.caption2).monospacedDigit().opacity(0.6)
          }
        }
      }
    }

    /// text is what a leg's cell writes, its own figure first and the running one under it where it
    /// has one, in the reader's units: a band as the locale's range, a climb and a loss signed, and a
    /// difficulty as the itinerary writes it. A sparkline writes nothing.
    static func text(_ cell: SegmentRowCell, units: UnitPreferences) -> [String] {
      switch cell {
      case .segment(let name):
        return [name]
      case .profile:
        return []
      case .distance(let leg, let total):
        return [formatDistance(leg, units: units)]
          + (total.map { [formatDistance($0, units: units)] } ?? [])
      case .elevation(let ascent, let descent, let totalAscent):
        let own = [
          ascent.map { "+" + formatElevation($0, units: units) },
          descent.map { "-" + formatElevation($0, units: units) },
        ].compactMap { $0 }.joined(separator: " ")
        return [own] + (totalAscent.map { ["+" + formatElevation($0, units: units)] } ?? [])
      case .altitude(let band, let single):
        return [
          band.map { formatAltitudeRange(min: $0.min, max: $0.max, units: units) }
            ?? formatElevation(single, units: units)
        ]
      case .duration(let seconds):
        return [formatDuration(seconds, units: units)]
      case .difficulty(let difficulty):
        return [difficulty?.rawValue ?? ""]
      }
    }

    /// Points at `row`, or at none, and writes the map links.
    private func point(at row: ItinerarySegmentRow?, drawing: ItineraryDrawing) {
      link.point(
        at: row?.key, value: row, target: drawing.segmentTarget(row), isEnabled: isEnabled,
        onHover: onHover, map: map, markerColor: markerColor, emphasisColor: emphasisColor)
    }

    /// The itinerary the resource shows, nil while there is none to draw.
    private var resolved: ResolvedItinerary? {
      if case .resolved(let itinerary)? = (reading.handed ?? own)?.state { return itinerary }
      return nil
    }

    /// Whether the itinerary is being read.
    private var isResolving: Bool {
      if case .resolving? = (reading.handed ?? own)?.state { return true }
      return false
    }
  }
#endif
