#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// LayersPanel is a map's layers picker (`geo.layers.picker-rows`), in the sections and the order
  /// of the map studio's layers panel:
  ///
  /// - **the terrains**, as picture cards, one base map among them;
  /// - **the enrichments**, as the platform's switches, each on or off by itself, in the accent, the
  ///   points of interest left to `POIPanel`, whose own picker drives them;
  /// - **the classic overlays**, as picture cards, one among every classic category's, shown a
  ///   category at a time behind a segmented `Picker` of the categories that hold one, drawn where
  ///   two or more do. It opens on the category the reader picked last in it, which the panel holds
  ///   for as long as it lives, else on the one holding the selected overlay, else on the first;
  /// - **the time**, where the host offers it, `offersTime`: a slider over the forecast window, one
  ///   stop an hour from 71 hours back to 144 ahead (`geo.layers.time-window`), ticked every day and
  ///   labelled two days back, now, and two and five days ahead, filled from now to its thumb, which
  ///   stands at the instant the selection pins, read out as the moment in the device's time zone
  ///   and its distance from now (`geo.layers.time-readout`), and pinning on release the instant of
  ///   the stop let go of, or none on now, through the selection (`geo.layers.time-slider`,
  ///   `LayersSelectionEngine.setInstant(_:)`). It steps one stop under each arrow key while it
  ///   holds the keyboard's focus, ringed, and under each adjustment of an assistive technology,
  ///   which reads the readout as its value. Its track is laid out around the reading of the clock
  ///   SwiftUI's environment carries, `mountayaClock`, each time the panel is drawn, and it is held,
  ///   under `layers.timeUnavailable`, where that clock reads no instant the time's rules hold.
  ///
  /// ```swift
  /// LayersPanel(
  ///   selection: layers, offersTime: true,
  ///   thumbnail: { _, slug in Image("layers/\(slug)") },
  ///   onLockedTap: { slug in showPlans(slug) })
  /// ```
  ///
  /// The time is the host's to offer: the Tile API refuses a publishable key or a share token a
  /// stamped tile asked more than 15 minutes from the moment it arrives, unless its organization's
  /// overlay time control allows it, so a slider offered where it does not would pin instants that
  /// draw nothing.
  ///
  /// It lists what `selection` holds and drives it, a press asking the selection's command for its
  /// card or its switch (`LayersSelectionEngine`), which drives the map. A card shows the picture
  /// `thumbnail` hands for its choice and its slug, and its name alone where it hands none; a card
  /// is drawn again where the picture handed is another. An entry `isLocked` names out of the
  /// viewer's reach shows its lock, and a press on it selects nothing and is handed to
  /// `onLockedTap`, for the app's own notice: what an agreement includes is the API's to enforce,
  /// and this lets an app that knows it say so before the request.
  ///
  /// Every word is the scope's (`mountayaScope(_:)`), each replaced by `strings` where it names the
  /// word's path, a counted word by a template whose `{count}` takes the count: the headings, the
  /// time's caption and readout its `layers` section's, and each terrain, category and overlay by
  /// the name the catalogue gives it in the scope's language, else in English, else by its slug.
  ///
  /// Each card and switch is drawn again only where what it shows or asks for changes, pressing
  /// through the panel as it is now, so a redraw of the panel redraws none it did not change. Each
  /// is the platform's touch target high, read as selected while checked, and ringed while it holds
  /// the keyboard's focus.
  public struct LayersPanel: View {
    private let selection: LayersSelectionEngine
    private let isLocked: ((String) -> Bool)?
    private let offersTime: Bool
    private let thumbnail: ((LayersPanelChoice, String) -> Image?)?
    private let strings: [String: String]?
    private let onLockedTap: ((String) -> Void)?

    /// press is what every card presses through: what its press asks for.
    @State private var press = PanelPress<LayersPanelPress>()
    /// toggles is what every switch presses through: its enrichment's slug.
    @State private var toggles = PanelPress<String?>()
    /// picked is the overlays' category the reader picked last, the panel's for as long as it
    /// lives, or nil for none.
    @State private var picked: String?
    @ViewScope private var scope: ElementsScope
    @Environment(\.mountayaClock) private var clock
    @Environment(\.renderProbe) private var probe
    @Environment(\.panelLayout) private var layout

    /// Creates the picker over `selection`, the time offered where `offersTime` says so, each card
    /// showing the picture `thumbnail` hands, the entries `isLocked` names locked, its words
    /// replaced by `strings` where it names theirs, and a press on a locked entry handed to
    /// `onLockedTap`.
    public init(
      selection: LayersSelectionEngine, isLocked: ((String) -> Bool)? = nil,
      offersTime: Bool = false, thumbnail: ((LayersPanelChoice, String) -> Image?)? = nil,
      strings: [String: String]? = nil, onLockedTap: ((String) -> Void)? = nil
    ) {
      self.selection = selection
      self.isLocked = isLocked
      self.offersTime = offersTime
      self.thumbnail = thumbnail
      self.strings = strings
      self.onLockedTap = onLockedTap
      _scope = ViewScope(strings: strings)
    }

    /// body is the picker's sections, each under its heading.
    public var body: some View {
      let _ = probe?.report("LayersPanel")
      let sections = layersPanelSections(
        selection.state, language: scope.language.rawValue, isLocked: isLocked ?? { _ in false },
        picked: picked, offersTime: offersTime)
      // A card or a switch SwiftUI keeps as it was drawn presses through the panel as it is now.
      let _ = press.hold { asked in
        Self.press(asked, selection: selection, onLockedTap: onLockedTap)
      }
      let _ = toggles.hold { slug in
        let rows = sections.first { $0.choice == .enrichment }?.rows ?? []
        if let row = rows.first(where: { sameText($0.slug, slug) }) {
          Self.press(
            layersPanelPress(.enrichment, row: row), selection: selection,
            onLockedTap: onLockedTap)
        }
      }
      let locked = scope.word("layers.locked")
      PanelSurface(title: scope.word("controls.layers")) {
        ForEach(sections, id: \.choice) { section in
          VStack(alignment: .leading, spacing: 6) {
            PanelHeading(text: scope.word(section.heading.word))
            content(of: section, locked: locked)
          }
        }
      }
      .environment(\.layersPanelPress, press)
      .environment(\.panelTogglePress, toggles)
      .viewWords(scope, stated: strings)
    }

    /// content is what a section lists under its heading, its words for a locked entry `locked`:
    /// its switches, its slider, or its cards, behind the categories' switch where it offers two or
    /// more, each of one type, so a section's kind costs no type of the others.
    private func content(of section: LayersPanelSection, locked: String) -> AnyView {
      switch section.choice {
      case .enrichment:
        return AnyView(
          ForEach(section.rows, id: \.slug) { row in
            LayersPanelSwitch(
              label: row.label, slug: row.slug, note: row.mark == .lock ? locked : nil,
              isOn: row.isChecked)
          })
      case .time:
        return AnyView(
          LayersPanelTime(
            selection: selection, window: timeSliderWindow(now: clock.now),
            words: ViewScope.Laid(scope: scope)))
      case .terrain, .overlay:
        let grid = LazyVGrid(columns: Self.columns, spacing: 8) {
          ForEach(section.rows, id: \.slug) { row in
            LayersPanelCard(
              label: row.label, slug: row.slug,
              pictureHeight: layout?.pictureHeight ?? ElementLayout.panelPictureHeight,
              note: row.mark == .lock ? locked : nil,
              image: thumbnail?(section.choice, row.slug), choice: section.choice,
              isChecked: row.isChecked)
          }
        }
        guard section.categories.count > 1 else { return AnyView(grid) }
        return AnyView(
          VStack(alignment: .leading, spacing: 6) {
            categories(section); grid
          })
      }
    }

    /// categories is the overlays' switch: a segmented control of the categories the section
    /// offers, the one it opens on selected, a pick held as the panel's own.
    private func categories(_ section: LayersPanelSection) -> some View {
      Picker(
        scope.word(section.heading.word),
        selection: Binding(get: { section.category ?? "" }, set: { picked = $0 })
      ) {
        ForEach(section.categories, id: \.slug) { category in
          Text(verbatim: category.name).tag(category.slug)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
    }

    /// columns is a grid of cards: three a line, as the map studio's panel sets them.
    private static let columns = Array(
      repeating: GridItem(.flexible(), spacing: 8), count: ElementLayout.panelLayerCardColumns)

    /// press carries out what a press asks for: the selection's command, or the report of a locked
    /// entry to `onLockedTap`.
    static func press(
      _ press: LayersPanelPress, selection: LayersSelectionEngine, onLockedTap: ((String) -> Void)?
    ) {
      switch press {
      case .locked(let slug): onLockedTap?(slug)
      case .command(.terrain, let slug): selection.setTerrain(slug)
      case .command(.overlay, let slug): selection.setOverlay(slug)
      case .command(.enrichment, let slug): selection.toggleEnrichment(slug)
      case .command(.time, _): break
      }
    }
  }

  /// LayersPanelCard is one picture card of a layers panel, a terrain's or a classic overlay's: the
  /// picture the host handed above its name, and its note, the word for a locked entry, pressed
  /// through the panel as it is now (`layersPanelPress`), asking for what
  /// `layersPanelPress(_:row:)` reads off it. It holds values alone, so SwiftUI draws a card again
  /// only where what it shows changes: a panel drawn again for a sibling's press or its host's own
  /// redraw redraws no card it did not change (`panel-rows` in the contract's
  /// `sdk/hot-paths.yaml`). Its fields leave no padding between them, as `PanelToggleEntry`'s do:
  /// the eight-byte ones first, then the environment's nine, then the bytes.
  struct LayersPanelCard: View {
    let label: String
    let slug: String
    /// pictureHeight is how tall the card's picture is drawn (`geo.panels.layout`).
    let pictureHeight: Double
    /// note is the word for a locked entry, or nil where the entry is in the viewer's reach.
    let note: String?
    let image: Image?

    @Environment(\.layersPanelPress) private var press

    let choice: LayersPanelChoice
    let isChecked: Bool

    var body: some View {
      Button {
        let mark: LayersPanelMark? = note != nil ? .lock : isChecked ? .tick : nil
        press?.press(
          layersPanelPress(
            choice, row: LayersPanelRow(slug: slug, label: label, isChecked: isChecked, mark: mark)
          ))
      } label: {
        LayersPanelCardFace(
          label: label, pictureHeight: pictureHeight, note: note, image: image,
          isChecked: isChecked)
      }
      .buttonStyle(ElementButtonStyle())
      .focusEffectDisabled()
      .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
  }

  /// LayersPanelCardFace draws a card: its picture above its name and its note, its edge
  /// `panel-border`, and `accent` twice as wide while it is selected, the platform's touch target
  /// high.
  struct LayersPanelCardFace: View {
    let label: String
    let pictureHeight: Double
    let note: String?
    let image: Image?
    let isChecked: Bool

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("LayersPanelCard " + label)
      VStack(spacing: 2) {
        if let image {
          image.resizable().scaledToFill().frame(height: pictureHeight).clipped()
        }
        Text(verbatim: label).font(.caption)
        if let note {
          Text(verbatim: note).font(.caption2)
        }
      }
      .padding(4)
      .frame(
        maxWidth: .infinity, minHeight: max(TouchTarget.side, ElementLayout.panelLayerCardHeight)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6).strokeBorder(
          tokenColor(isChecked ? tokens.accent : tokens.panelBorder, in: themeScheme(colorScheme)),
          lineWidth: isChecked ? 2 : 1)
      )
      .contentShape(Rectangle())
    }
  }

  /// LayersPanelSwitch is one enrichment of a layers panel, on or off by itself: the platform's
  /// switch, or, for an entry out of the viewer's reach, its lock and the word for it in place of
  /// the switch, a press on it reported rather than selecting (`geo.layers.picker-rows`). It presses
  /// through the panel as it is now (`panelTogglePress`), handing it its slug, and holds values
  /// alone, so SwiftUI draws a switch again only where what it shows changes (`panel-rows` in the
  /// contract's `sdk/hot-paths.yaml`). Its fields leave no padding between them, as
  /// `PanelToggleEntry`'s do: the eight-byte ones first, then the environment's nine, then the flag.
  struct LayersPanelSwitch: View {
    let label: String
    let slug: String
    /// note is the word for a locked entry, which stands in place of the switch, or nil.
    let note: String?

    @Environment(\.panelTogglePress) private var press

    let isOn: Bool

    var body: some View {
      LayersPanelSwitchFace(label: label, note: note, isOn: isOn) { press?.press(slug) }
    }
  }

  /// LayersPanelSwitchFace draws a layers panel's switch: the platform's `Toggle` in the switch
  /// style, tinted in `accent`, the platform's touch target high and ringed while it holds the
  /// keyboard's focus, or a locked entry's row, its lock and its word where the switch would be.
  struct LayersPanelSwitchFace: View {
    let label: String
    let note: String?
    let isOn: Bool
    let toggle: () -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("LayersPanelSwitch " + label)
      if let note {
        PanelRow(label: label, isChecked: false, action: toggle) {
          PanelRowMarks(glyph: "locked", note: note, isOn: false)
        }
      } else {
        Toggle(isOn: Binding(get: { isOn }, set: { _ in toggle() })) {
          Text(verbatim: label)
        }
        .toggleStyle(.switch)
        .tint(tokenColor(tokens.accent, in: themeScheme(colorScheme)))
        .frame(minHeight: ControlButton<EmptyView>.side)
        .focused($isFocused)
        .focusEffectDisabled()
        .modifier(FocusRing(cornerRadius: 6, stated: isFocused))
      }
    }
  }
#endif
