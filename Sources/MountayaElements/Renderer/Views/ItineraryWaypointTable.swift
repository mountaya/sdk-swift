#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import Foundation
  public import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// ItineraryWaypointTable is an itinerary's places as a table: a row per pass of a place in
  /// itinerary order, a loop's shared start and finish two rows, each stating, column by column, its
  /// glyph and name, the sparkline with the stretch reaching it lit, its running distance, the climb
  /// and loss since the place before, and, as the app asks, its altitude, its services, its cut-off
  /// and its fields (`geo.profile.waypoint-rows`, `geo.profile.waypoint-table-cells`).
  ///
  /// ```swift
  /// ItineraryWaypointTable(itineraryId: "itin_abc", cache: itineraries, map: map)
  /// ```
  ///
  /// It reads the itinerary as `ItineraryProfile` does, through `cache`, or through `engine`, an
  /// engine of the app's the table shows and never closes.
  ///
  /// Over its rows stand a chip per service its places offer, sorted by the reader's name for it,
  /// and a row stays only where its place offers every service picked (`geo.profile.amenity-filter`);
  /// the choice is the app's where it hands `picked`, and the table's own otherwise. A cut-off and a
  /// `date` field are written only by `formatCutoffAt`, the time zone being the app's. A row a reader
  /// points at, a pointer over it or a tap on it, pins a marker on `map` at its place under
  /// `markerId` (`map.profile.cursor-marker`), taken down as the pointer leaves or the table goes;
  /// `onHover` takes that over, and a tap hands the place's id to `onWaypointTap`. `.disabled(true)`
  /// draws the table and drives nothing.
  ///
  /// Its words are the scope's `table`, `profile` and `amenities` sections, each replaced by
  /// `strings` where it names the word's path, its glyphs the scope's marker set, its figures
  /// written in `units`, and its colours the tokens'.
  public struct ItineraryWaypointTable: View {
    private let reading: ItineraryReading
    private let map: MapEngine?
    private let units: UnitPreferences?
    private let columns: [WaypointTableColumn]
    private let picked: Binding<[RestSchema.WaypointAmenity]>?
    private let markerId: String
    private let markerColor: String?
    private let formatCutoffAt: ((Date) -> String)?
    private let strings: [String: String]?
    private let onHover: ((ItineraryWaypointRow?) -> Void)?
    private let onWaypointTap: ((String) -> Void)?
    private let onError: ((any Error) -> Void)?

    /// own is the table's own engine over the app's cache, made as it is first asked, or nil where
    /// it reads through the app's.
    @State private var own: ItineraryResourceEngine?
    @State private var ownPicked: [RestSchema.WaypointAmenity] = []
    @State private var link: MapLink<String>
    @State private var failures: FailureRelay
    @ViewScope private var scope: ElementsScope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    /// Creates the table of the places of the itinerary `itineraryId` names on `surface`, read
    /// through `cache`, its rows pointed on `map`, its figures in `units`, its `columns` in order,
    /// the services picked held in `picked` where the app holds them, its marker under `markerId` in
    /// `markerColor`, a cut-off written by `formatCutoffAt`, its words replaced by `strings` where it
    /// names theirs, the row pointed at handed to `onHover` in place of the map, a place's id to
    /// `onWaypointTap`, and each failure to read to `onError`, once.
    public init(
      itineraryId: String?,
      cache: ItineraryResourceCache,
      surface: RestSchema.ReadSurface? = nil,
      map: MapEngine? = nil,
      units: UnitPreferences? = nil,
      columns: [WaypointTableColumn] = defaultWaypointTableColumns,
      picked: Binding<[RestSchema.WaypointAmenity]>? = nil,
      markerId: String = waypointTableCursorMarkerId,
      markerColor: String? = nil,
      formatCutoffAt: ((Date) -> String)? = nil,
      strings: [String: String]? = nil,
      onHover: ((ItineraryWaypointRow?) -> Void)? = nil,
      onWaypointTap: ((String) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        reading: .cache(cache, itineraryId: itineraryId, surface: surface), map: map, units: units,
        columns: columns, picked: picked, markerId: markerId, markerColor: markerColor,
        formatCutoffAt: formatCutoffAt, strings: strings, onHover: onHover,
        onWaypointTap: onWaypointTap, onError: onError)
    }

    /// Creates the table of the places of the itinerary `engine` reads, an engine of the app's the
    /// table shows and never closes, every other argument as the table of an itinerary read by id
    /// takes it.
    public init(
      engine: ItineraryResourceEngine,
      map: MapEngine? = nil,
      units: UnitPreferences? = nil,
      columns: [WaypointTableColumn] = defaultWaypointTableColumns,
      picked: Binding<[RestSchema.WaypointAmenity]>? = nil,
      markerId: String = waypointTableCursorMarkerId,
      markerColor: String? = nil,
      formatCutoffAt: ((Date) -> String)? = nil,
      strings: [String: String]? = nil,
      onHover: ((ItineraryWaypointRow?) -> Void)? = nil,
      onWaypointTap: ((String) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        reading: .engine(engine), map: map, units: units, columns: columns, picked: picked,
        markerId: markerId, markerColor: markerColor, formatCutoffAt: formatCutoffAt,
        strings: strings, onHover: onHover, onWaypointTap: onWaypointTap, onError: onError)
    }

    /// Creates the table of the places of the itinerary `reading` reads.
    ///
    /// Both public initializers call it, and it is kept out of line so an app carries its body once
    /// rather than once in each.
    @inline(never)
    private init(
      reading: ItineraryReading,
      map: MapEngine?,
      units: UnitPreferences?,
      columns: [WaypointTableColumn],
      picked: Binding<[RestSchema.WaypointAmenity]>?,
      markerId: String,
      markerColor: String?,
      formatCutoffAt: ((Date) -> String)?,
      strings: [String: String]?,
      onHover: ((ItineraryWaypointRow?) -> Void)?,
      onWaypointTap: ((String) -> Void)?,
      onError: ((any Error) -> Void)?
    ) {
      self.reading = reading
      self.map = map
      self.units = units
      self.columns = columns
      self.picked = picked
      self.markerId = markerId
      self.markerColor = markerColor
      self.formatCutoffAt = formatCutoffAt
      self.strings = strings
      self.onHover = onHover
      self.onWaypointTap = onWaypointTap
      self.onError = onError
      _link = State(initialValue: MapLink(markerId: markerId))
      _failures = State(initialValue: FailureRelay())
      _scope = ViewScope(strings: strings)
    }

    /// body is the filter's chips, the header and a row per place left, or the empty line.
    public var body: some View {
      let drawing = ItineraryDrawing(resolved: resolved, legs: nil)
      let figures = units ?? UnitPreferences(language: scope.locale)
      let scheme = themeScheme(colorScheme)
      let rows = drawing.waypointRows
      let choice = picked?.wrappedValue ?? ownPicked
      let filter = amenityFilter(rows, picked: choice, scope: scope)
      // The handler of the latest drawing is the one a failure reaches.
      let _ = failures.hold(onError)
      VStack(alignment: .leading, spacing: 0) {
        if rows.isEmpty {
          Text(verbatim: scope.word(isResolving ? "table.loading" : "table.waypointEmpty"))
            .font(.footnote)
            .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
        } else {
          if !filter.available.isEmpty {
            chips(filter.available, picked: choice, scheme: scheme)
          }
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
          if filter.shown.isEmpty {
            Text(verbatim: scope.word("table.waypointFilterEmpty"))
              .font(.footnote)
              .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
              .padding(.vertical, 8)
          }
          ForEach(filter.shown, id: \.key) { row in
            rowView(row, drawing: drawing, units: figures, scheme: scheme)
          }
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: scope.word("table.waypointTitle")))
      .viewWords(scope, stated: strings)
      .task(id: reading.question) {
        // Made as it is first asked, so a table SwiftUI makes and drops asks nothing, and followed
        // before it is asked, so every failure it shows is handed on.
        let read = reading.read(own, following: failures)
        if read !== own { own = read }
      }
      .onChange(of: isEnabled) {
        if !isEnabled { point(at: nil, drawing: drawing) }
      }
      .onDisappear { point(at: nil, drawing: drawing) }
    }

    /// The filter's chips, each pressed to toggle its service anywhere in the platform's touch
    /// target around its 32-point capsule, and read as selected while picked.
    private func chips(
      _ available: [RestSchema.WaypointAmenity], picked choice: [RestSchema.WaypointAmenity],
      scheme: ThemeScheme
    ) -> some View {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(available, id: \.rawValue) { amenity in
            AmenityChip(
              label: amenityName(amenity, in: scope),
              isPicked: choice.contains { sameText($0, amenity) }
            ) {
              press(amenity, picked: choice)
            }
          }
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: scope.word("table.amenityFilter")))
    }

    /// press toggles `amenity` in the choice `choice`, at its end where it was not picked
    /// (`toggleAmenity(_:in:)`), writing the app's choice where it holds one and the table's own
    /// otherwise.
    func press(_ amenity: RestSchema.WaypointAmenity, picked choice: [RestSchema.WaypointAmenity]) {
      let next = toggleAmenity(amenity, in: choice)
      if let picked {
        picked.wrappedValue = next
      } else {
        ownPicked = next
      }
    }

    /// One place's row, lit where it is pointed at.
    private func rowView(
      _ row: ItineraryWaypointRow, drawing: ItineraryDrawing, units figures: UnitPreferences,
      scheme: ThemeScheme
    ) -> some View {
      HStack(spacing: 8) {
        ForEach(columns, id: \.self) { column in
          cell(
            waypointRowCell(
              row, column: column, glyphs: scope.markerGlyphs, units: figures,
              formatCutoffAt: formatCutoffAt),
            series: drawing.series, units: figures, scheme: scheme
          )
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.vertical, 6)
      .frame(minHeight: 44)
      .background(link.pointed == row.key ? tokenColor(tokens.tableRowHover, in: scheme) : .clear)
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
      .accessibilityAddTraits(link.pointed == row.key ? [.isButton, .isSelected] : .isButton)
      .accessibilityAction { tap(row, drawing: drawing) }
    }

    /// A tap on a row, or its activation by an assistive technology: it points at the row, or at
    /// none where it was pointed at, and hands the place's id to `onWaypointTap`.
    private func tap(_ row: ItineraryWaypointRow, drawing: ItineraryDrawing) {
      guard isEnabled else { return }
      point(at: link.pointed == row.key ? nil : row, drawing: drawing)
      onWaypointTap?(row.place.id)
    }

    /// One cell of a place's row, as its column states it.
    @ViewBuilder
    private func cell(
      _ cell: WaypointRowCell, series: ElevationSeries, units figures: UnitPreferences,
      scheme: ThemeScheme
    ) -> some View {
      switch cell {
      case .waypoint(let glyph, _):
        HStack(spacing: 6) {
          Glyph(glyph, in: scope.markerGlyphs, size: 16, ink: .foreground)
          Text(verbatim: Self.text(cell, units: figures, scope: scope))
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
        }
      case .profile(let lit):
        ItinerarySparkline(series: series, lit: lit).frame(height: 24)
      case .distance, .elevation, .altitude:
        Text(verbatim: Self.text(cell, units: figures, scope: scope))
          .font(.subheadline)
          .monospacedDigit()
      case .amenities(let services):
        HStack(spacing: 4) {
          ForEach(Array(services.enumerated()), id: \.offset) { _, amenity in
            let glyph = amenityGlyph(amenity)
            if scope.markerGlyphs.markup[glyph] != nil {
              Glyph(
                glyph, in: scope.markerGlyphs, size: 14, ink: .foreground,
                label: amenityName(amenity, in: scope))
            } else {
              Text(verbatim: badgeFallback(amenityName(amenity, in: scope), on: .cell) ?? "")
                .font(.caption2)
            }
          }
        }
      case .cutoff, .properties:
        Text(verbatim: Self.text(cell, units: figures, scope: scope)).font(.caption).lineLimit(3)
      }
    }

    /// text is what a place's cell writes, in the reader's units and words: its name, the pin's word
    /// for a place with none; its running distance; its climb and loss signed; its altitude; its
    /// services by name; its cut-off as the app's formatter wrote it; and each field as its label and
    /// its value, a line each. A sparkline writes nothing.
    static func text(_ cell: WaypointRowCell, units: UnitPreferences, scope: ElementsScope)
      -> String
    {
      switch cell {
      case .waypoint(_, let name):
        return name ?? scope.word("profile.unlabelledWaypoint")
      case .profile:
        return ""
      case .distance(let total):
        return formatDistance(total, units: units)
      case .elevation(let ascent, let descent):
        return [
          ascent.map { "+" + formatElevation($0, units: units) },
          descent.map { "-" + formatElevation($0, units: units) },
        ].compactMap { $0 }.joined(separator: " ")
      case .altitude(let altitude):
        return formatElevation(altitude, units: units)
      case .amenities(let services):
        return services.map { amenityName($0, in: scope) }.joined(separator: ", ")
      case .cutoff(let moment):
        return moment ?? ""
      case .properties(let fields):
        return fields.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
      }
    }

    /// Points at `row`, or at none, and pins the marker at its place.
    private func point(at row: ItineraryWaypointRow?, drawing: ItineraryDrawing) {
      link.point(
        at: row?.key, value: row, target: drawing.waypointTarget(row), isEnabled: isEnabled,
        onHover: onHover, map: map, markerColor: markerColor, emphasisColor: nil)
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
  /// AmenityChip is one chip of a waypoint table's services filter: the service's name on a
  /// capsule 32 points high, white on the accent while it is picked, pressed anywhere in the
  /// platform's touch target around it, and read as selected while it is picked.
  struct AmenityChip: View {
    let label: String
    let isPicked: Bool
    let action: () -> Void

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let scheme = themeScheme(colorScheme)
      Button(action: action) {
        Text(verbatim: label)
          .font(.caption)
          .padding(.horizontal, 10)
          .frame(minHeight: 32)
          .foregroundStyle(isPicked ? Color.white : tokenColor(tokens.panelFg, in: scheme))
          .background(
            isPicked
              ? tokenColor(tokens.accent, in: scheme) : tokenColor(tokens.panelBg, in: scheme),
            in: Capsule()
          )
          .overlay(Capsule().strokeBorder(tokenColor(tokens.panelBorder, in: scheme)))
          .focusRing(cornerRadius: 16)
          .touchTarget()
      }
      .buttonStyle(ElementButtonStyle(ringsLabel: false))
      .focusEffectDisabled()
      .accessibilityAddTraits(isPicked ? .isSelected : [])
    }
  }
#endif
