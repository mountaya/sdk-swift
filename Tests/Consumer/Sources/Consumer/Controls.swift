import Foundation
import MountayaClient
import MountayaGeo

/// Controls reads the controls' and the panels' rules as an app drawing its own does: a theme's
/// tokens under a scheme, the words of a nested scope, a counted word and a template, the pickers'
/// models and their presses, the zoom window's ends, and the two engines over a map of the app's
/// own.
enum Controls {
  /// themes reads a token under each scheme, a consumer's value standing in both.
  static func themes() -> [HexColor] {
    var tokens = ElementTokens.standard
    tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
    tokens.controlBg = ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#101010"))
    let dash: [Double] = themeTokenValue(tokens.profileCursorDash, in: .dark)
    _ = dash
    return ThemeScheme.allCases.flatMap { scheme in
      [themeTokenValue(tokens.accent, in: scheme), themeTokenValue(tokens.controlBg, in: scheme)]
    }
  }

  /// words reads a nested scope's words, a counted word and a filled template.
  static func words() -> [String] {
    let french = scopeOf(
      .standard,
      stating: ElementsScopeStatement(
        language: .fr, locale: "fr-CH",
        words: .bySection(["controls": ["zoomIn": "Plus"]]), controlGlyphs: .control,
        markerGlyphs: .marker))
    let inner = scopeOf(french, stating: ElementsScopeStatement(locale: "fr-BE"))
    let count = resolveBundle(.elements, language: inner.language)["search"]
    var counted = ""
    if case .object(let search)? = count, let word = search["resultCount"] {
      counted = countedText(word, count: 1_234, language: inner.language) ?? ""
    }
    return [
      inner.word("controls.zoomIn"), inner.locale, counted,
      filledText("{elapsed} stop", value: "15 min"), inner.controlGlyphs.name,
      inner.markerGlyphs.name, ElementsScope.standard.word("tooltips.geolocate.title"),
    ]
  }

  /// pickers reads what each picker offers and what a press on it asks for.
  static func pickers(_ catalogue: TileSchema.Layers) -> [String] {
    let selection = LayersSelection(
      catalogue: catalogue, terrain: "topo", overlay: "slopes", enrichments: ["hillshade"])
    var read: [String] = []
    for section in layersPanelSections(
      selection, language: "fr-CA", isLocked: { $0 == "snow" }, picked: "hazards", offersTime: true)
    {
      read.append(section.heading.word)
      read += section.categories.map { "\($0.slug) \($0.name)" }
      for row in section.rows {
        switch layersPanelPress(section.choice, row: row) {
        case .command(let choice, let slug): read.append("\(choice.rawValue) \(slug)")
        case .locked(let slug): read.append("locked \(slug)")
        }
        read.append(row.mark?.rawValue ?? row.label)
      }
      _ = (section.category, section.choice == .enrichment)
    }
    let offer = poiPanelRows(
      drawn: ["parking", "spring"], isKeyVisible: { $0 != "spring" },
      groups: [POIPanelGroup(id: "water", label: "Water", keys: ["spring"], glyph: "pin")],
      activeGroups: nil, labels: ["parking": "Parking"])
    read += offer.rows.map { "\($0.id) \($0.label) \($0.keys) \($0.isVisible) \($0.glyph ?? "")" }
    _ = (offer.isAnyVisible, poiPanelNoteZoom(12), POIPanelRows(rows: [], isAnyVisible: false))
    let units = UnitPreferences(language: "fr-CA")
    for choice in preferenceChoices(units) {
      for option in choice.options where option.isChecked {
        switch option.label {
        case .word(let word): read.append("\(choice.field.rawValue) \(word)")
        case .name(let name): read.append("\(choice.field.rawValue) \(name)")
        }
      }
    }
    let press = preferencePress(units, pressing: .language(.de))
    read.append("\(press.next.language) \(press.relabel?.rawValue ?? "")")
    _ = (
      PreferenceValue.pace(.perDistance).field, PreferenceField.allCases,
      PreferenceOption(value: .slope(.degrees), label: .word("degrees"), isChecked: true),
      PreferenceChoice(field: .slope, options: []), PreferencePress(next: units, relabel: nil),
      LayersPanelRow(slug: "topo", label: "Topo", isChecked: true, mark: .tick),
      LayersPanelSection(
        heading: LayersPanelHeading(word: "layers.overlays"), choice: .overlay,
        category: "conditions", rows: [],
        categories: [LayersPanelCategory(slug: "conditions", name: "Conditions")]),
      LayersPanelChoice.allCases, LayersPanelMark.allCases, poisOverlaySlug
    )
    return read
  }

  /// time reads the time's rules as a slider of an app's own draws them: the moment shown, the
  /// stamped addresses, the track, its ticks, a release and the thumb's readout.
  static func time(_ catalogue: TileSchema.Layers, now: Date) -> [String] {
    let pinned = Date(timeIntervalSince1970: 1_773_576_000)
    let shown = overlayInstant(pinned: nil, now: now)
    let stamped: [TimestampedSource] = timestampedSources(
      catalogue, overlay: "snow-depth", at: shown ?? pinned)
    let window: TimeSliderWindow = timeSliderWindow(now: now)
    let thumb = window.value(at: pinned)
    let ticks: [TimeSliderTick] = timeSliderTicks(window)
    let released: TimeSliderRelease? = timeSliderRelease(window, at: thumb)
    let readout: TimeSliderReadout = timeSliderReadout(window, at: thumb)
    _ = (
      window.start, window.nowValue, window.maxValue, window.date(at: 0), released?.pin,
      TimestampedSource(sourceId: "s", tiles: []), TimeSliderTick(value: 71, word: nil),
      TimeSliderRelease(pin: nil),
      TimeSliderReadout(instant: nil, word: "layers.timeNow", count: nil)
    )
    // One statement a value, which the floor's type checker reads in its time.
    var read: [String] = []
    for source in stamped {
      read.append(source.sourceId)
      read += source.tiles
    }
    for tick in ticks {
      read.append("\(tick.value) \(tick.word ?? "")")
    }
    read.append(readout.word)
    read.append(readout.count.map(String.init) ?? "")
    read.append(readout.instant.map { "\($0)" } ?? "")
    return read
  }

  /// zoomEnds reads which zoom control the end of a window disables.
  static func zoomEnds() -> [ZoomStep] {
    let end = zoomLimitReached(14, window: ZoomBounds(minZoom: 4, maxZoom: 14))
    _ = (ZoomWindowEnd.allCases, end == ZoomWindowEnd.none)
    return zoomControlsDisabled(at: end)
  }

  /// engines drives a layers selection and a locate control over a map of the app's own.
  @MainActor
  static func engines() async {
    let map = OwnMap()
    let selection = LayersSelectionEngine(map: map)
    selection.setTerrain("topo")
    selection.setOverlay("slopes")
    selection.toggleEnrichment("hillshade")
    selection.setInstant(Date(timeIntervalSince1970: 1_773_576_000))
    selection.configure(map: map)
    for await held in selection.subscribe() {
      _ = (held.catalogue, held.terrain, held.overlay, held.enrichments, held.instant, held.refusal)
      break
    }
    selection.close()

    let control = GeolocateControlEngine(map: map)
    control.locate(onError: { error in _ = error })
    control.configure(map: nil)
    let state: GeolocateControlState = control.state
    _ = (state.isBusy, state.isBlocked, state.isLive)
    for await shown in control.subscribe() {
      _ = shown
      break
    }
    control.close()
  }
}

/// OwnMap is a map of an app's own, which a layers selection drives and a locate control stands
/// over, conformed from outside. It is bound to the main actor, as the engines that drive it are.
@MainActor
final class OwnMap: LayersSelectionTarget, GeolocateControlTarget {
  var terrain: String? = "topo"

  func loadLayers() async throws -> TileSchema.Layers {
    throw CancellationError()
  }

  func setTerrain(_ slug: String?) async throws {}
  func setOverlay(_ slug: String) async throws {}
  func clearOverlay() async throws {}
  func addEnrichment(_ slug: String) async throws {}
  func removeEnrichment(_ slug: String) async throws {}
  func setInstant(_ instant: Date?) async throws {}

  func locate() async throws -> [Double] { [6.8652, 45.9237] }
  func isLocationRefused() async throws -> Bool { false }
}
