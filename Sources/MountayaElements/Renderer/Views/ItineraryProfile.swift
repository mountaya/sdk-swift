#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import Foundation
  public import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// ItineraryProfile is an itinerary's elevation profile: the stat strip over it, the curve and
  /// what stands on it, and, as the app asks, the elevation scale, the distance scale with the
  /// places' names, a band strip, a chip per leg and a navigator over the window drawn.
  ///
  /// ```swift
  /// ItineraryProfile(itineraryId: "itin_abc", cache: itineraries, map: map)
  ///   .frame(height: 160)
  /// ```
  ///
  /// It reads the itinerary `itineraryId` names on `surface` through `cache`, one read for every
  /// element asking about it (`geo.data.itinerary-resource`), or the one `engine` reads, an engine
  /// of the app's the profile shows and never closes, the app choosing the itinerary through its
  /// `configure(cache:itineraryId:surface:)`, and draws its geometry, the server's
  /// figures over the ones it reads off the geometry, its legs and its places. A chain the app
  /// states, `legs`, is also the curve (`sdk/SPEC.md` §7). An itinerary with no altitude draws no
  /// plot and states its empty line, its strip still stating its length. Each failure to read is
  /// handed to `onError` once, a read asked again after an invalidation that fails in turn
  /// included, and draws the empty state.
  ///
  /// Every figure is the profile's rules', drawn in a 100-unit square stretched over the chart
  /// (`geo.profile.*`): the scale anchored on `anchor`, the curve painted as `coloring` asks, the
  /// places pinned on the curve with their services above them and their names under the axis, and
  /// the cut-offs marked where `formatCutoffAt` writes them. A scrub reads the window through 240
  /// columns, the cursor standing on a sample; the strip then states the cursor's distance,
  /// altitude and grade, unless the card at the cursor, `ProfileParts.tooltip`, states them.
  ///
  /// The window is the app's where it hands `window`, a nil window being the whole itinerary, and
  /// the profile's own otherwise, which the navigator moves and a new itinerary resets. While a
  /// scrub stands over a profile with a `map`, a marker stands on the map at the sample, under
  /// `markerId` in `markerColor` (`map.profile.cursor-marker`), and the leg under the cursor, the
  /// later of two at the meter they share, is lit on the map's emphasis slot in `emphasisColor`
  /// (`map.profile.emphasis`); both are taken down as the scrub ends or the profile leaves. An
  /// `onHover` handler takes the map links over: it is handed the sample and the profile writes
  /// nothing to the map. `.disabled(true)` draws the profile and drives nothing. `highlighted` lights
  /// the leg a segment id names, its own or a member's (`geo.profile.row-match`), tinted under the
  /// curve; `onWaypointTap` is handed a pin's place's id; and where the app hands `onSegmentTap` a
  /// leg's chip is a button, a press handing over the id `geo.profile.row-match` answers to,
  /// `group:` then the group's id for a collapsed group, and writing nothing to the map, as the
  /// segment table's `onSegmentTap` does (`sdk/SPEC.md` §7).
  ///
  /// Its words are the scope's (`mountayaScope(_:)`), its `profile` and `amenities` sections, each
  /// replaced by `strings` where it names the word's path, its figures written in `units`, the
  /// scope's locale in metric unless the app hands others, and its colours the tokens'
  /// (`mountayaTokens(_:)`).
  public struct ItineraryProfile: View {
    private let reading: ItineraryReading
    private let legs: [ItineraryLeg]?
    private let map: MapEngine?
    private let units: UnitPreferences?
    private let stats: [StatStripStat]
    private let coloring: ProfileColoring
    private let bands: [ProfileClass]
    private let parts: ProfileParts
    private let anchor: ProfileAnchor
    private let window: Binding<ProfileRange?>?
    private let highlighted: String?
    private let emphasisColor: String?
    private let markerId: String
    private let markerColor: String?
    private let formatCutoffAt: ((Date) -> String)?
    private let strings: [String: String]?
    private let onHover: ((ElevationPoint?) -> Void)?
    private let onWaypointTap: ((String) -> Void)?
    private let onSegmentTap: ((String) -> Void)?
    private let onError: ((any Error) -> Void)?

    /// own is the profile's own engine over the app's cache, made as it is first asked, or nil
    /// where it reads through the app's.
    @State private var own: ItineraryResourceEngine?
    @State private var ownWindow: ProfileRange?
    /// cursor holds where the cursor stands apart from the profile, whose body never reads it, so
    /// a scrub redraws the parts that read it and never the profile.
    @State private var cursor: ProfileCursor
    @State private var failures: FailureRelay
    /// curves holds the chart's curve across the profile's renders, so a scrub builds none again.
    @State private var curves = ProfileCurves()
    @ViewScope private var scope: ElementsScope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.renderProbe) private var probe

    /// Creates the profile of the itinerary `itineraryId` names on `surface`, read through `cache`,
    /// its chain `legs` where the app states one, its links drawn on `map`, its figures in `units`,
    /// its strip stating `stats`, its curve painted as `coloring` asks with `bands` under it, the
    /// `parts` drawn beside it, its scale anchored on `anchor`, its window held in `window` where the
    /// app holds it, the leg `highlighted` names lit, the map's emphasis in `emphasisColor`, its
    /// cursor marker under `markerId` in `markerColor`, a cut-off written by `formatCutoffAt`, its
    /// words replaced by `strings` where it names theirs, the cursor handed to `onHover` in place
    /// of the map, a pin's place's id to `onWaypointTap`, a leg's id to `onSegmentTap` as its chip
    /// is pressed, and each failure to read the itinerary to `onError`, once.
    public init(
      itineraryId: String?,
      cache: ItineraryResourceCache,
      surface: RestSchema.ReadSurface? = nil,
      legs: [ItineraryLeg]? = nil,
      map: MapEngine? = nil,
      units: UnitPreferences? = nil,
      stats: [StatStripStat] = defaultStatStripStats,
      coloring: ProfileColoring = .plain,
      bands: [ProfileClass] = [],
      parts: ProfileParts = .standard,
      anchor: ProfileAnchor = .route,
      window: Binding<ProfileRange?>? = nil,
      highlighted: String? = nil,
      emphasisColor: String? = nil,
      markerId: String = profileCursorMarkerId,
      markerColor: String? = nil,
      formatCutoffAt: ((Date) -> String)? = nil,
      strings: [String: String]? = nil,
      onHover: ((ElevationPoint?) -> Void)? = nil,
      onWaypointTap: ((String) -> Void)? = nil,
      onSegmentTap: ((String) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        reading: .cache(cache, itineraryId: itineraryId, surface: surface), legs: legs, map: map,
        units: units, stats: stats, coloring: coloring, bands: bands, parts: parts, anchor: anchor,
        window: window, highlighted: highlighted, emphasisColor: emphasisColor, markerId: markerId,
        markerColor: markerColor, formatCutoffAt: formatCutoffAt, strings: strings,
        onHover: onHover, onWaypointTap: onWaypointTap, onSegmentTap: onSegmentTap,
        onError: onError)
    }

    /// Creates the profile of the itinerary `engine` reads, an engine of the app's the profile
    /// shows and never closes, every other argument as the profile of an itinerary read by id
    /// takes it.
    public init(
      engine: ItineraryResourceEngine,
      legs: [ItineraryLeg]? = nil,
      map: MapEngine? = nil,
      units: UnitPreferences? = nil,
      stats: [StatStripStat] = defaultStatStripStats,
      coloring: ProfileColoring = .plain,
      bands: [ProfileClass] = [],
      parts: ProfileParts = .standard,
      anchor: ProfileAnchor = .route,
      window: Binding<ProfileRange?>? = nil,
      highlighted: String? = nil,
      emphasisColor: String? = nil,
      markerId: String = profileCursorMarkerId,
      markerColor: String? = nil,
      formatCutoffAt: ((Date) -> String)? = nil,
      strings: [String: String]? = nil,
      onHover: ((ElevationPoint?) -> Void)? = nil,
      onWaypointTap: ((String) -> Void)? = nil,
      onSegmentTap: ((String) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        reading: .engine(engine), legs: legs, map: map, units: units, stats: stats,
        coloring: coloring, bands: bands, parts: parts, anchor: anchor, window: window,
        highlighted: highlighted, emphasisColor: emphasisColor, markerId: markerId,
        markerColor: markerColor, formatCutoffAt: formatCutoffAt, strings: strings,
        onHover: onHover, onWaypointTap: onWaypointTap, onSegmentTap: onSegmentTap,
        onError: onError)
    }

    /// Creates the profile of the itinerary `reading` reads.
    ///
    /// Both public initializers call it, and it is kept out of line so an app carries its body once
    /// rather than once in each.
    @inline(never)
    private init(
      reading: ItineraryReading,
      legs: [ItineraryLeg]?,
      map: MapEngine?,
      units: UnitPreferences?,
      stats: [StatStripStat],
      coloring: ProfileColoring,
      bands: [ProfileClass],
      parts: ProfileParts,
      anchor: ProfileAnchor,
      window: Binding<ProfileRange?>?,
      highlighted: String?,
      emphasisColor: String?,
      markerId: String,
      markerColor: String?,
      formatCutoffAt: ((Date) -> String)?,
      strings: [String: String]?,
      onHover: ((ElevationPoint?) -> Void)?,
      onWaypointTap: ((String) -> Void)?,
      onSegmentTap: ((String) -> Void)?,
      onError: ((any Error) -> Void)?
    ) {
      self.reading = reading
      self.legs = legs
      self.map = map
      self.units = units
      self.stats = stats
      self.coloring = coloring
      self.bands = bands
      self.parts = parts
      self.anchor = anchor
      self.window = window
      self.highlighted = highlighted
      self.emphasisColor = emphasisColor
      self.markerId = markerId
      self.markerColor = markerColor
      self.formatCutoffAt = formatCutoffAt
      self.strings = strings
      self.onHover = onHover
      self.onWaypointTap = onWaypointTap
      self.onSegmentTap = onSegmentTap
      self.onError = onError
      _cursor = State(initialValue: ProfileCursor(markerId: markerId))
      _failures = State(initialValue: FailureRelay())
      _scope = ViewScope(strings: strings)
    }

    /// body is the strip, then the plot and the parts beside it, or the empty line. It never reads
    /// where the cursor stands: the parts the cursor moves read it, so a scrub redraws them alone.
    public var body: some View {
      let _ = probe?.report("ItineraryProfile")
      let drawing = ItineraryDrawing(resolved: resolved, legs: legs)
      let figures = units ?? UnitPreferences(language: scope.locale)
      let shown = shownWindow(drawing)
      // The handler of the latest drawing is the one a failure reaches.
      let _ = failures.hold(onError)
      VStack(alignment: .leading, spacing: 8) {
        if !stats.isEmpty {
          // The strip states the cursor unless the card at the cursor does, and reads it only then.
          ProfileStatStrip(
            characteristics: drawing.characteristics, series: drawing.series, stats: stats,
            units: figures, cursor: parts.contains(.tooltip) ? nil : cursor)
        }
        if drawing.series.hasElevation {
          plot(drawing, window: shown, units: figures)
        } else {
          Text(verbatim: scope.word("profile.empty"))
            .font(.footnote)
            .foregroundStyle(tokenColor(tokens.dimmed, in: themeScheme(colorScheme)))
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: scope.word("profile.title")))
      .viewWords(scope, stated: strings)
      .task(id: reading.question) {
        // Made as it is first asked, so a profile SwiftUI makes and drops asks nothing, and
        // followed before it is asked, so every failure it shows is handed on.
        let read = reading.read(own, following: failures)
        if read !== own { own = read }
      }
      .onChange(of: reading.question) {
        // A new itinerary starts over: its window, and its cursor.
        ownWindow = nil
        scrub(nil, drawing: drawing)
      }
      .onChange(of: isEnabled) {
        if !isEnabled { scrub(nil, drawing: drawing) }
      }
      .onDisappear { scrub(nil, drawing: drawing) }
    }

    /// The plot and the parts drawn beside it.
    @ViewBuilder
    private func plot(
      _ drawing: ItineraryDrawing, window: ProfileRange, units figures: UnitPreferences
    ) -> some View {
      let series = drawing.series
      let domain =
        anchor == .route || (anchor == .window && window == drawing.whole)
        ? profileDomain(series) : anchoredDomain(series, anchor: anchor, window: window)
      let placement = placeOnCurve(
        series, geometry: drawing.geometry, domain: domain, window: window, places: drawing.places)
      let classes = classes(series)
      let litRow = highlighted.flatMap { id in drawing.rows.first { rowStandsFor($0, id: id) } }
      ProfileChart(
        series: series, domain: domain, window: window, painted: painted(classes),
        placement: placement,
        stacks: parts.contains(.amenities) ? amenityStacks(placement.pins) : [],
        lit: litRow.map { ProfileRange(from: $0.from, to: $0.to) }, cursor: cursor,
        tooltip: parts.contains(.tooltip), stretches: classes,
        showsElevationAxis: parts.contains(.elevationAxis), units: figures,
        formatCutoffAt: formatCutoffAt, onScrub: { scrub($0, drawing: drawing) },
        onWaypointTap: onWaypointTap, curves: curves
      )
      .frame(minHeight: 100)
      if parts.contains(.distanceAxis) {
        ProfileDistanceAxis(
          totalDistance: series.totalDistance, window: window, dividers: placement.dividers,
          units: figures)
      }
      if !bands.isEmpty {
        ProfileStretchStrip(
          spans: placeSpans(bands, totalDistance: series.totalDistance, window: window),
          label: scope.word("profile.bands"))
      }
      if parts.contains(.sections) {
        ProfileSections(
          rows: placeSpans(drawing.rows, totalDistance: series.totalDistance, window: window),
          units: figures, onSegmentTap: onSegmentTap)
      }
      if parts.contains(.navigator) {
        ProfileNavigator(series: series, domain: profileDomain(series), window: window) { moved in
          if let binding = self.window {
            binding.wrappedValue = moved
          } else {
            ownWindow = moved
          }
        }
      }
    }

    /// The itinerary the resource shows, nil while there is none to draw.
    private var resolved: ResolvedItinerary? {
      if case .resolved(let itinerary)? = (reading.handed ?? own)?.state { return itinerary }
      return nil
    }

    /// The window drawn: the app's or the profile's own, the whole itinerary where neither states
    /// one, held to the itinerary and to the narrowest window.
    private func shownWindow(_ drawing: ItineraryDrawing) -> ProfileRange {
      let asked = window.map { $0.wrappedValue } ?? ownWindow
      return clampRange(asked ?? drawing.whole, totalDistance: drawing.series.totalDistance)
    }

    /// The stretches the curve is classified into, which the readout names, by the coloring.
    private func classes(_ series: ElevationSeries) -> [ProfileClass] {
      switch coloring {
      case .plain, .stretches: return []
      case .classes(let classes): return classes
      case .slope(let buckets):
        return slopeStretches(series.points, buckets: buckets).map { stretch in
          var named = stretch
          named.label = scope.word("profile.slope.\(stretch.label)")
          return named
        }
      }
    }

    /// The stretches the curve is painted in.
    private func painted(_ classes: [ProfileClass]) -> [CurveColor] {
      if case .stretches(let stretches) = coloring { return stretches }
      return classes.map { CurveColor(from: $0.from, to: $0.to, color: $0.color) }
    }

    /// Moves the cursor to the sample at `index`, or takes it away, and writes the map links.
    private func scrub(_ index: Int?, drawing: ItineraryDrawing) {
      let point = index.flatMap {
        drawing.series.points.indices.contains($0) ? drawing.series.points[$0] : nil
      }
      cursor.point(
        at: point?.index, value: point, target: drawing.cursorTarget(at: point?.index),
        isEnabled: isEnabled, onHover: onHover, map: map, markerColor: markerColor,
        emphasisColor: emphasisColor)
    }

  }

  /// ProfileStatStrip is the row of figures over a profile (`geo.profile.stat-strip`): each its word
  /// over its value, written in the reader's units, a difficulty as the itinerary writes it, and
  /// the distance, the altitude and the grade where the cursor stands, where it states the cursor.
  /// It reads the cursor itself, and only where it states it, so a scrub redraws the strip and not
  /// the profile, and a strip under a card at the cursor not at all.
  struct ProfileStatStrip: View {
    let characteristics: ResolvedCharacteristics
    let series: ElevationSeries
    let stats: [StatStripStat]
    let units: UnitPreferences
    /// cursor is the cursor the strip states, nil where it states the itinerary alone.
    let cursor: ProfileCursor?

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfileStatStrip")
      let cells = statStripCells(
        characteristics,
        cursor: cursor?.sample(in: series).map {
          StatStripCursor(
            distance: $0.distance, elevation: $0.elevation,
            grade: gradeAt(series.points, distance: $0.distance))
        }, stats: stats)
      let dimmed = tokenColor(tokens.dimmed, in: themeScheme(colorScheme))
      HStack(alignment: .firstTextBaseline, spacing: 16) {
        ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
          VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: scope.word("profile.\(cell.stat.rawValue)"))
              .font(.caption2)
              .foregroundStyle(dimmed)
            Text(verbatim: Self.value(cell, units: units))
              .font(.subheadline.weight(.semibold))
              .monospacedDigit()
          }
          .accessibilityElement(children: .combine)
        }
      }
    }

    /// value is a cell's figure as the reader's units write it.
    static func value(_ cell: StatStripCell, units: UnitPreferences) -> String {
      switch cell {
      case .distance(let meters): formatDistance(meters, units: units)
      case .duration(let seconds): formatDuration(seconds, units: units)
      case .ascent(let meters), .descent(let meters), .elevation(let meters):
        formatElevation(meters, units: units)
      case .grade(let degrees): formatSlope(degrees, units: units)
      case .difficulty(let difficulty): difficulty.rawValue
      }
    }
  }

  /// ProfileStretchStrip is the strip of coloured stretches under a profile's chart, each placed
  /// where it overlaps the window (`geo.profile.window-spans`), painted in its colour and read by
  /// its word, the strip read by `label`.
  struct ProfileStretchStrip: View {
    let spans: [PlacedSpan<ProfileClass>]
    let label: String

    @Environment(\.sharedScope) private var scope
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfileStretchStrip")
      GeometryReader { proxy in
        ZStack(alignment: .topLeading) {
          ForEach(spans, id: \.index) { placed in
            hexColor(HexColor(hex: placed.span.color))
              .frame(width: (placed.end - placed.start) / profileViewBox * proxy.size.width)
              .offset(x: placed.start / profileViewBox * proxy.size.width)
              .accessibilityElement()
              .accessibilityLabel(
                Text(
                  verbatim: placed.span.label.isEmpty
                    ? scope.word("profile.unlabelledBand") : placed.span.label))
          }
        }
      }
      .frame(height: 8)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: label))
    }
  }

  /// ProfileSections is a chip per leg under a profile's chart, each as wide as its leg's stretch
  /// of the window (`geo.profile.window-spans`) and stating its length and climb
  /// (`geo.profile.section-chips`). The row is 36 points high at the default text size and grows
  /// with Dynamic Type, so a chip's two lines are drawn whole at a larger text size.
  ///
  /// A chip is a button where the app listens for a press of a leg, `onSegmentTap`, and none where
  /// it does not, so a profile no press reaches offers none to the keyboard or to assistive
  /// technologies; a press hands over the leg's id, and while the profile is disabled presses
  /// nothing (`press(_:isEnabled:onSegmentTap:)`).
  struct ProfileSections: View {
    let rows: [PlacedSpan<ItinerarySegmentRow>]
    let units: UnitPreferences
    var onSegmentTap: ((String) -> Void)?

    /// rowHeight is the row's height, 36 points at the default text size, scaled with the reader's.
    @ScaledMetric(relativeTo: .caption2) private var rowHeight: CGFloat = 36

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfileSections")
      let scheme = themeScheme(colorScheme)
      GeometryReader { proxy in
        ZStack(alignment: .topLeading) {
          ForEach(rows, id: \.index) { placed in
            pressable(placed.span, scheme: scheme)
              .frame(
                width: max(0, (placed.end - placed.start) / profileViewBox * proxy.size.width - 2)
              )
              .offset(x: placed.start / profileViewBox * proxy.size.width + 1)
          }
        }
      }
      .frame(height: rowHeight)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: scope.word("profile.sections")))
    }

    /// press hands the id of the leg `row` stands for to `onSegmentTap`, the id
    /// `geo.profile.row-match` answers to, `group:` then the group's id for a collapsed group, and
    /// nothing while the profile is disabled. It writes nothing to the map: a press is the app's.
    static func press(
      _ row: ItinerarySegmentRow, isEnabled: Bool, onSegmentTap: ((String) -> Void)?
    ) {
      guard isEnabled else { return }
      onSegmentTap?(row.id)
    }

    /// One leg's chip, a button where the app listens for a press, carrying the focus ring while it
    /// holds the keyboard's focus.
    @ViewBuilder
    private func pressable(_ row: ItinerarySegmentRow, scheme: ThemeScheme) -> some View {
      if let onSegmentTap {
        Button {
          Self.press(row, isEnabled: isEnabled, onSegmentTap: onSegmentTap)
        } label: {
          chip(row, scheme: scheme).focusRing()
        }
        .buttonStyle(ElementButtonStyle(ringsLabel: false))
        .focusEffectDisabled()
      } else {
        chip(row, scheme: scheme)
      }
    }

    /// One leg's chip: its colour, its name and its figures.
    private func chip(_ row: ItinerarySegmentRow, scheme: ThemeScheme) -> some View {
      let cells = sectionChipCells(row.metrics)
      let figures = cells.map { cell in
        switch cell.stat {
        case .distance: formatDistance(cell.value, units: units)
        case .ascent: "+" + formatElevation(cell.value, units: units)
        case .descent: "-" + formatElevation(cell.value, units: units)
        case .grade: formatSlope(cell.value, units: units)
        }
      }
      return VStack(alignment: .leading, spacing: 1) {
        Text(verbatim: row.name).font(.caption2.weight(.semibold)).lineLimit(1)
        Text(verbatim: figures.joined(separator: " · ")).font(.caption2).lineLimit(1)
      }
      .padding(.horizontal, 4)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .background(
        (row.color.map { hexColor(HexColor(hex: $0)) } ?? tokenColor(tokens.accent, in: scheme))
          .opacity(0.14),
        in: RoundedRectangle(cornerRadius: 4)
      )
      .accessibilityElement(children: .combine)
    }
  }
#endif
