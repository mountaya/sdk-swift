#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// POIPanel toggles what a map's points of interest show, one concept at a time
  /// (`geo.layers.poi-rows`).
  ///
  /// The unit is the catalogue's key, a map concept a fill and the label over it may both draw, so
  /// a toggle never hides one and leaves the other floating. Its rows are what the map draws at the
  /// points-of-interest rank, so a catalogue that gains a concept gains a row, and a map drawing no
  /// point of interest shows no panel at all. `keys` curates them, a row per key it lists that is
  /// drawn, in its own order; `groups`, which supersede `keys`, a row per concept of the app's own,
  /// driving the drawn keys it names. A key's row is labelled from `labels`, else by the key.
  ///
  /// A row is on while any key it drives is shown, read off the map as it changes, whoever changed
  /// it; `activeGroups` holds the groups the app keeps on itself, which the rows then read instead.
  /// A press shows or hides the row's keys on the map, unless the app hands a handler in its place,
  /// `onToggle` for a key's row and `onToggleGroup` for a group's, told the row and the state it
  /// asks for. `showsAllToggle` adds a row over them all, on while any row is, its press handed to
  /// `onToggleAll` where the app hands one. Below `minZoom`, the zoom the overlay draws from, it
  /// says the overlay draws nothing yet, never at it. `.disabled(true)` disables every row. Its
  /// words are the scope's `pois` section (`mountayaScope(_:)`), each replaced by `strings` where it
  /// names the word's path.
  ///
  /// Each row is drawn again only where what it shows changes, pressing through the panel as it is
  /// now, and the note reads the live zoom apart from the panel, so neither a camera moving nor a
  /// redraw of the panel redraws a row it did not change.
  public struct POIPanel: View {
    private let map: MapEngine?
    private let keys: [String]?
    private let groups: [POIPanelGroup]?
    private let activeGroups: [String]?
    private let labels: [String: String]
    private let minZoom: Double?
    private let showsAllToggle: Bool
    private let strings: [String: String]?
    private let onToggle: ((String, Bool) -> Void)?
    private let onToggleGroup: ((String, Bool) -> Void)?
    private let onToggleAll: ((Bool) -> Void)?

    /// press is what every row presses through: a row's id, nil for the row over them all.
    @State private var press = PanelPress<String?>()
    @ViewScope private var scope: ElementsScope
    @Environment(\.renderProbe) private var probe

    /// Creates the panel over `map`, its rows curated by `keys` or `groups`, a key's row labelled
    /// from `labels`, the note standing below `minZoom`, a master row where `showsAllToggle` says
    /// so, its words replaced by `strings` where it names theirs, and each press handed to the
    /// handler the app hands in place of the map.
    public init(
      map: MapEngine?, keys: [String]? = nil, groups: [POIPanelGroup]? = nil,
      activeGroups: [String]? = nil, labels: [String: String] = [:], minZoom: Double? = nil,
      showsAllToggle: Bool = false, strings: [String: String]? = nil,
      onToggle: ((String, Bool) -> Void)? = nil, onToggleGroup: ((String, Bool) -> Void)? = nil,
      onToggleAll: ((Bool) -> Void)? = nil
    ) {
      self.map = map
      self.keys = keys
      self.groups = groups
      self.activeGroups = activeGroups
      self.labels = labels
      self.minZoom = minZoom
      self.showsAllToggle = showsAllToggle
      self.strings = strings
      self.onToggle = onToggle
      self.onToggleGroup = onToggleGroup
      self.onToggleAll = onToggleAll
      _scope = ViewScope(strings: strings)
    }

    /// body is the master row, the note and the rows, or nothing where no row is offered. It never
    /// reads the camera: the note does.
    public var body: some View {
      let _ = probe?.report("POIPanel")
      let offer = self.offer
      // A row SwiftUI keeps as it was drawn presses through the panel as it is now.
      let _ = press.hold { id in pressed(id) }
      if !offer.rows.isEmpty {
        PanelSurface(title: scope.word("controls.pois")) {
          if showsAllToggle {
            PanelToggleEntry(
              label: scope.word("pois.displayOnMap"), glyph: nil, id: nil,
              isOn: offer.isAnyVisible)
          }
          POIPanelNote(map: map, minZoom: minZoom)
          VStack(alignment: .leading, spacing: 0) {
            PanelHeading(text: scope.word("pois.categories"))
            ForEach(offer.rows, id: \.id) { row in
              PanelToggleEntry(
                label: row.label, glyph: row.glyph, id: row.id, isOn: row.isVisible)
            }
          }
        }
        .environment(\.panelTogglePress, press)
        .viewWords(scope, stated: strings)
      }
    }

    /// pressed carries out a press on the row `id` names, nil for the row over them all, as the
    /// map offers it now.
    func pressed(_ id: String?) {
      let offer = self.offer
      guard let id else {
        toggleAll(!offer.isAnyVisible, rows: offer.rows)
        return
      }
      guard let row = offer.rows.first(where: { sameText($0.id, id) }) else { return }
      toggle(row, visible: !row.isVisible)
    }

    /// offer is what the panel offers, read off the map: the keys it draws at the
    /// points-of-interest rank and whether each is shown.
    var offer: POIPanelRows {
      poiPanelRows(
        drawn: map?.drawnLayerKeys(rank: LayerRank.poi.rank) ?? [],
        isKeyVisible: { key in map?.isKeyVisible(key) ?? true }, keys: keys, groups: groups,
        activeGroups: activeGroups, labels: labels)
    }

    /// toggle is a press on `row` asking for it to be `visible`: the app's handler where it hands
    /// one, each of the row's keys shown or hidden on the map otherwise.
    func toggle(_ row: POIPanelRow, visible: Bool) {
      let handler = groups == nil ? onToggle : onToggleGroup
      if let handler {
        handler(row.id, visible)
        return
      }
      for key in row.keys {
        map?.setKeyVisibility(key, visible: visible)
      }
    }

    /// toggleAll is a press on the master row asking for every row to be `visible`: the app's
    /// handler where it hands one, every row's keys shown or hidden on the map otherwise.
    func toggleAll(_ visible: Bool, rows: [POIPanelRow]) {
      if let onToggleAll {
        onToggleAll(visible)
        return
      }
      for key in rows.flatMap(\.keys) {
        map?.setKeyVisibility(key, visible: visible)
      }
    }

    /// isNoted is whether the panel notes the overlay draws nothing: while the camera's `zoom` is
    /// below `minZoom`, never at it, and never with no camera, no floor or one that is no number.
    static func isNoted(zoom: Double?, minZoom: Double?) -> Bool {
      guard let zoom else { return false }
      return !(zoom >= poiPanelNoteZoom(minZoom))
    }
  }

  /// POIPanelNote compares the live zoom with the floor of a points-of-interest panel's overlay,
  /// apart from the panel, as a store's selector reads a store: the comparison runs as the camera
  /// moves, and what it says, `POIPanelNoteLine`, a value alone, is drawn again only where the
  /// comparison flips, never once per zoom frame and never once per settle of a camera driven frame
  /// by frame (`zoom-threshold` in the contract's `sdk/hot-paths.yaml`).
  struct POIPanelNote: View {
    let map: MapEngine?
    let minZoom: Double?

    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("POIPanelNote")
      POIPanelNoteLine(isNoted: POIPanel.isNoted(zoom: map?.state.camera.zoom, minZoom: minZoom))
    }
  }

  /// POIPanelNoteLine says a points-of-interest panel's overlay draws nothing yet, where `isNoted`,
  /// and is nothing otherwise. It reads neither the scope nor the tokens, which `POIPanelNoteText`
  /// draws with, and its fields leave no padding between them, as `PanelToggleEntry`'s do, so it is
  /// drawn again only where `isNoted` changes.
  struct POIPanelNoteLine: View {
    @Environment(\.renderProbe) private var probe

    let isNoted: Bool

    var body: some View {
      let _ = probe?.report("POIPanelNoteLine")
      if isNoted {
        POIPanelNoteText()
      }
    }
  }

  /// POIPanelNoteText is a points-of-interest panel's note, in the scope's words with its info
  /// glyph, in the `dimmed` token under the scheme in force.
  struct POIPanelNoteText: View {
    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Glyph("info", in: scope.controlGlyphs, size: 14, ink: .foreground)
        Text(verbatim: scope.word("pois.zoomWarning")).font(.footnote)
      }
      .foregroundStyle(tokenColor(tokens.dimmed, in: themeScheme(colorScheme)))
    }
  }
#endif
