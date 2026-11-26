#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  public import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// SearchControl is a search box over Mountaya's unified search, with its results under it: the
  /// box, the filters, the scope to the visible area, a line for each branch that failed, the
  /// elements' word `search.error` beside its retry, `search.retry`, and never the message the API
  /// wrote, which stays on the branch's `SearchBranchError` for the app to log, the rows with their
  /// second lines, and the empty state (`geo.search.list-state`).
  ///
  /// It shows a `SearchEngine`, which waits for the typing to pause, asks one request per branch,
  /// abandons a round a later one replaced, falls back from the visible area once where it found
  /// nothing there and asks again as the camera of its map rests, and whose rows never answer
  /// another query than the one in the box (`geo.search.*`). Its own engine reads the Data API
  /// through the client of its map, as the map's content does, unless the app hands `fetch` in its
  /// place; with neither it is inert, a box that answers nothing.
  ///
  /// The app hands `engine` where it holds the search itself, a typing pause of its own among it:
  /// the control then shows and drives that engine, the reader's typing, its scope to the visible
  /// area and the camera of its map, never configures it nor closes it, and the engine's own
  /// configuration stands in for `targets`, `language`, `limit`, `wording` and `fetch`. An engine
  /// starts unconfined where its app states nothing, and the control's own starts confined.
  ///
  /// ```swift
  /// MapView(map)
  ///   .overlay(alignment: .topLeading) {
  ///     SearchControl(map: map).padding()
  ///   }
  /// ```
  ///
  /// It starts confined to the visible area of its map, a default the reader changes with its
  /// toggle, and the app with `isConfined`; with no map it confines nothing and shows no toggle.
  /// Picking a row moves the map's camera onto it, at once where the reader asked for reduced
  /// motion, and draws it in the map's search highlight, in
  /// the `accent` the tokens around the control read under the colour scheme in force
  /// (`pickTarget(_:)`, `map.search.result-highlight`); a row that marks nothing, a collection,
  /// takes the mark of the pick before down, and the control takes its map's search highlight down
  /// as it leaves the screen or is handed another map.
  /// `onSelect` stands in for the whole pick, for an app that routes a pick its own way.
  ///
  /// `query` and `isConfined` hand the box's text and its scope to the app where it holds them, the
  /// control keeping each in step with its engine both ways, and reading its engine's where the app
  /// holds neither. `targets`, `language` and `limit` are what each round of its own engine asks:
  /// every branch, the scope's language as the Data API spells it, and the API's own cap unless the
  /// app states others. Every figure is stated in `units`, the scope's locale in metric unless the
  /// app hands others, and `wording` words a row's title and second line, its units standing over
  /// `units` for the second line where it states some. `onError` is handed each failure of a
  /// branch's request of its own engine; the list shows a line for it either way.
  ///
  /// Its words are the scope's (`mountayaScope(_:)`), its `search` and `profile` sections, each
  /// replaced by `strings` where it names the word's path, and its colours the tokens'
  /// (`mountayaTokens(_:)`), read under the colour scheme in force. Its clear
  /// button, its filter chips and each retry are pressed anywhere in the platform's touch target
  /// around them, 44 points each way, each keeping the look it is drawn with.
  /// `.disabled(true)` disables the box.
  public struct SearchControl: View {
    private let map: MapEngine?
    /// handed is the app's engine, which the control shows and drives and never closes, or nil for
    /// the control's own.
    private let handed: SearchEngine?
    private let query: Binding<String>?
    private let isConfined: Binding<Bool>?
    private let targets: [DataSchema.SearchTarget]
    private let language: DataSchema.Language?
    private let limit: SearchLimit?
    private let units: UnitPreferences?
    private let wording: SearchWording?
    private let fetch: SearchFetch?
    private let strings: [String: String]?
    private let onSelect: ((SearchRow) -> Void)?
    private let onError: ((any Error) -> Void)?

    /// own is the control's own engine, shown where the app hands none.
    @State private var own: SearchEngine
    @State private var relay = SearchRelay()
    @State private var filter = SearchFilter.all
    @State private var isDismissed = false
    /// focus is the part of the control the keyboard's focus stands in, nil where it stands
    /// outside the control.
    @FocusState private var focus: SearchPart?
    @ViewScope private var scope: ElementsScope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    /// Creates the control over `map`, showing `engine` where the app hands one, its text held in
    /// `query` and its scope in `isConfined` where the app hands them, each round of its own engine
    /// asking `targets` in `language` under `limit`, its figures in `units` and its rows worded by
    /// `wording`, its requests sent through `fetch` in place of the map's client where the app hands
    /// one, its words replaced by `strings` where it names theirs, a pick handed to `onSelect` in
    /// place of the map where the app hands one, and each failed request of its own engine to
    /// `onError`.
    public init(
      map: MapEngine?,
      engine: SearchEngine? = nil,
      query: Binding<String>? = nil,
      isConfined: Binding<Bool>? = nil,
      targets: [DataSchema.SearchTarget] = searchSectionOrder,
      language: DataSchema.Language? = nil,
      limit: SearchLimit? = nil,
      units: UnitPreferences? = nil,
      wording: SearchWording? = nil,
      fetch: SearchFetch? = nil,
      strings: [String: String]? = nil,
      onSelect: ((SearchRow) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      // The control's own engine is made inert, with no transport, and handed one as the control
      // appears, so a control SwiftUI makes and drops asks nothing; the text the box starts with
      // owes no pause.
      self.init(
        map: map, handed: engine,
        own: SearchEngine(
          configuration: SearchConfiguration(targets: targets), query: query?.wrappedValue ?? "",
          isConfined: map == nil ? false : isConfined?.wrappedValue ?? true),
        query: query, isConfined: isConfined, targets: targets, language: language, limit: limit,
        units: units, wording: wording, fetch: fetch, strings: strings, onSelect: onSelect,
        onError: onError)
    }

    /// Creates the control over `map`, its own engine `own`, which it configures as it does the
    /// one it makes.
    init(
      map: MapEngine?, own: SearchEngine, query: Binding<String>? = nil,
      isConfined: Binding<Bool>? = nil, targets: [DataSchema.SearchTarget] = searchSectionOrder,
      language: DataSchema.Language? = nil, limit: SearchLimit? = nil,
      units: UnitPreferences? = nil, wording: SearchWording? = nil, fetch: SearchFetch? = nil,
      strings: [String: String]? = nil, onSelect: ((SearchRow) -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        map: map, handed: nil, own: own, query: query, isConfined: isConfined, targets: targets,
        language: language, limit: limit, units: units, wording: wording, fetch: fetch,
        strings: strings, onSelect: onSelect, onError: onError)
    }

    /// Creates the control over `map`, showing `handed`, the app's engine, where it is given, and
    /// `own` otherwise.
    private init(
      map: MapEngine?, handed: SearchEngine?, own: SearchEngine, query: Binding<String>?,
      isConfined: Binding<Bool>?, targets: [DataSchema.SearchTarget],
      language: DataSchema.Language?, limit: SearchLimit?, units: UnitPreferences?,
      wording: SearchWording?, fetch: SearchFetch?, strings: [String: String]?,
      onSelect: ((SearchRow) -> Void)?, onError: ((any Error) -> Void)?
    ) {
      self.map = map
      self.handed = handed
      self.query = query
      self.isConfined = isConfined
      self.targets = targets
      self.language = language
      self.limit = limit
      self.units = units
      self.wording = wording
      self.fetch = fetch
      self.strings = strings
      self.onSelect = onSelect
      self.onError = onError
      _own = State(initialValue: own)
      _scope = ViewScope(strings: strings)
    }

    /// engine is the engine the control shows: the app's, or its own.
    private var engine: SearchEngine {
      handed ?? own
    }

    /// body is the box, and under it the list while the focus stands anywhere in the control over a
    /// query the reader has not dismissed (`isSearchListShown(hasFocus:query:isDismissed:)`).
    public var body: some View {
      let state = engine.state
      let list = searchListState(state, filter: filter)
      let figures = units ?? UnitPreferences(language: scope.locale)
      // The handler of the latest drawing is the one a failure reaches.
      let _ = relay.hold(onError)
      VStack(alignment: .leading, spacing: 8) {
        SearchField(text: typing, focus: $focus)
        if isListShown {
          SearchList(
            list: list, isSearching: state.isSearching, filter: $filter,
            isConfined: map == nil ? nil : confining, units: figures, focus: $focus,
            retry: { engine.retry() }, select: select)
        }
      }
      .frame(minWidth: 280, maxWidth: 400, alignment: .leading)
      .viewWords(scope, stated: strings)
      .onAppear(perform: start)
      .onDisappear { engine.setOpen(false) }
      .task(id: Self.identity(of: map)) { [map] in
        // The highlight is the control's: it is taken down from the map the control showed as the
        // control leaves or is handed another map, so no mark stays where nothing points at it.
        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(3_600))
        }
        map?.setSearchHighlight(nil)
      }
      .onChange(of: query?.wrappedValue) { _, written in
        guard let written else { return }
        engine.setQuery(written)
      }
      .onChange(of: isConfined?.wrappedValue) { _, written in
        guard let written else { return }
        engine.setConfined(map != nil && written)
      }
      .onChange(of: isListShown) { _, isShown in engine.setOpen(isShown) }
      .onChange(of: focus) { _, part in
        // The focus coming back to the box lifts a dismissal, and moving within the list keeps it.
        if part == .box { isDismissed = false }
      }
      .onChange(of: viewport) { _, viewport in
        if map != nil || handed == nil { engine.setCamera(viewport) }
      }
      .onChange(of: question) { _, _ in
        if handed == nil { engine.configure(configuration) }
      }
      .onChange(of: Self.statusText(list.status, in: scope)) { _, line in
        if !line.isEmpty {
          AccessibilityNotification.Announcement(line).post()
        }
      }
    }

    // MARK: - What the control holds

    /// typing is the box's text as the field edits it: each edit is written where the app holds
    /// the text, and told to the engine at once, so the reader's typing reaches the search however
    /// the app holds the text, a binding SwiftUI hands as it stood when the control was drawn
    /// included. A text the app writes reaches the engine as the app's binding changes, and where
    /// the app holds none the box shows the engine's own.
    private var typing: Binding<String> {
      let held = query
      let engine = self.engine
      return Binding(
        get: { held?.wrappedValue ?? engine.query },
        set: { text in
          held?.wrappedValue = text
          isDismissed = false
          engine.setQuery(text)
        })
    }

    /// shownQuery is the box's text: the app's where it holds it, the engine's otherwise.
    private var shownQuery: String {
      query?.wrappedValue ?? engine.query
    }

    /// confining is the scope to the visible area as its toggle edits it: each press is written
    /// where the app holds the scope, and told to the engine at once; where the app holds none, the
    /// toggle shows the engine's own.
    private var confining: Binding<Bool> {
      let held = isConfined
      let engine = self.engine
      return Binding(
        get: { held?.wrappedValue ?? engine.isConfined },
        set: { isConfined in
          held?.wrappedValue = isConfined
          engine.setConfined(isConfined)
        })
    }

    /// isListShown is whether the list shows, as Geo's
    /// `isSearchListShown(hasFocus:query:isDismissed:)` reads the focus anywhere in the control, its
    /// box, its chips or its list, the box's text and the reader's dismissal.
    private var isListShown: Bool {
      isSearchListShown(hasFocus: focus != nil, query: shownQuery, isDismissed: isDismissed)
    }

    /// viewport is the camera a round reads, the map's at rest, or none with no map.
    private var viewport: MapViewport? {
      map.map { MapViewport(center: $0.state.camera.center, zoom: $0.state.camera.zoom) }
    }

    /// accent is the accent the tokens around the control read under the colour scheme in force,
    /// which a pick is drawn in.
    private var accent: HexColor {
      themeTokenValue(tokens.accent, in: themeScheme(colorScheme))
    }

    /// question is what a round asks besides its query, which a change of asks the engine to be
    /// configured again.
    private var question: SearchQuestion {
      let figures = wording?.units ?? units ?? UnitPreferences(language: scope.locale)
      return SearchQuestion(
        map: Self.identity(of: map), hasFetch: fetch != nil, targets: targets,
        language: language ?? dataLanguageFor(scope.language.rawValue), limit: limit,
        unitsLanguage: figures.language, unitsLength: figures.length)
    }

    /// configuration is what the engine asks its rounds with: the app's transport, else the map's
    /// client, the language and the cap, the branches, the words, and the relay of the handler.
    private var configuration: SearchConfiguration {
      let figures = units ?? UnitPreferences(language: scope.locale)
      let words = wording ?? SearchWording()
      let relay = self.relay
      let onError: @MainActor @Sendable (any Error) -> Void = { error in relay.onError?(error) }
      return SearchConfiguration(
        fetch: fetch ?? Self.transport(of: map),
        language: language ?? dataLanguageFor(scope.language.rawValue), limit: limit,
        targets: targets,
        wording: SearchWording(units: words.units ?? figures, resolveLabel: words.resolveLabel),
        onError: onError)
    }

    // MARK: - What the control does

    /// start hands the engine what the control holds as it appears: the camera of its map, the
    /// text and the scope the app holds, and, for its own engine, the transport. An engine the app
    /// hands keeps the camera it was told where the control has no map, and its configuration.
    private func start() {
      if map != nil || handed == nil {
        engine.setCamera(viewport)
      }
      if let query {
        engine.setQuery(query.wrappedValue)
      }
      if let isConfined {
        engine.setConfined(map != nil && isConfined.wrappedValue)
      }
      if handed == nil {
        engine.configure(configuration)
      }
    }

    /// select is a pick of `row`: the list dismissed, the control left, and the row shown on the map
    /// or handed to `onSelect`.
    private func select(_ row: SearchRow) {
      isDismissed = true
      focus = nil
      Self.pick(row, map: map, accent: accent, reducesMotion: reducesMotion, onSelect: onSelect)
    }

    /// pick shows `row` on `map`, its camera moved onto it and its mark drawn in `accent`, the
    /// mark of the pick before taken down where it marks nothing, or hands it to `onSelect` alone
    /// where the app handed one. The camera travels there, unless `reducesMotion`, the reader's
    /// asking for reduced motion, has it jump: a fit then lands at once, and a flight is a jump.
    static func pick(
      _ row: SearchRow, map: MapEngine?, accent: HexColor, reducesMotion: Bool = false,
      onSelect: ((SearchRow) -> Void)?
    ) {
      if let onSelect {
        onSelect(row)
        return
      }
      guard let map else { return }
      let pick = pickTarget(row.payload)
      switch pick.camera {
      case .fit(let bounds)?:
        try? map.fitBounds(bounds, with: CameraFit(duration: reducesMotion ? .zero : nil))
      case .fly(let center, let zoom)?:
        let target = CameraTarget(center: center, zoom: zoom)
        if reducesMotion {
          try? map.jump(to: target)
        } else {
          try? map.fly(to: target)
        }
      case nil:
        break
      }
      map.setSearchHighlight(pick.mark, accent: accent)
    }

    /// identity is the identity of `map`, or nil for none.
    static func identity(of map: MapEngine?) -> ObjectIdentifier? {
      map.map(ObjectIdentifier.init)
    }

    /// transport is the search request of `map`'s client, or none with no map.
    static func transport(of map: MapEngine?) -> SearchFetch? {
      guard let client = map?.client else { return nil }
      return { input in try await client.data.search(input: input) }
    }

    // MARK: - Words

    /// statusText is what the status line announces in the words of `scope`: the failure, the
    /// emptiness or the count of rows, and nothing where it announces none.
    static func statusText(_ status: SearchListStatus?, in scope: ElementsScope) -> String {
      switch status {
      case nil:
        return ""
      case .resultCount(let count)?:
        guard case .object(let search)? = scope.words["search"], let word = search["resultCount"],
          let text = countedText(word, count: count, language: scope.language)
        else { return "" }
        return text
      case let status?:
        return scope.word("search.\(status.key)")
      }
    }

    /// filterLabel is the word a filter's chip reads in `scope`.
    static func filterLabel(_ filter: SearchFilter, in scope: ElementsScope) -> String {
      switch filter {
      case .all: scope.word("search.categoryAll")
      case .itineraries: scope.word("search.categoryItineraries")
      case .places: scope.word("search.categoryPlaces")
      case .zones: scope.word("search.categoryZones")
      }
    }

    /// title is a row's title with the runs the query matched set strong, each run read through the
    /// title's scalars.
    static func title(_ row: SearchRow) -> AttributedString {
      let scalars = row.title.unicodeScalars
      var title = AttributedString()
      var cursor = scalars.startIndex
      for range in row.matched where range.lowerBound >= cursor {
        title += AttributedString(String(scalars[cursor..<range.lowerBound]))
        var matched = AttributedString(String(scalars[range]))
        matched.inlinePresentationIntent = .stronglyEmphasized
        title += matched
        cursor = range.upperBound
      }
      title += AttributedString(String(scalars[cursor...]))
      return title
    }
  }

  /// SearchQuestion is what a search control's rounds ask besides their query, compared as a
  /// round's identity is: a change of it configures the engine again.
  struct SearchQuestion: Equatable {
    let map: ObjectIdentifier?
    let hasFetch: Bool
    let targets: [DataSchema.SearchTarget]
    let language: DataSchema.Language
    let limit: SearchLimit?
    let unitsLanguage: String
    let unitsLength: RestSchema.UnitLength
  }

  /// SearchPart is a part of a search control the keyboard's focus can stand in: its box, a filter
  /// chip, its scope's toggle, a failed branch's retry or a row of its list. The list shows while
  /// the focus stands in any of them.
  enum SearchPart: Hashable {
    case box
    case filter(SearchFilter)
    case scope
    case retry(DataSchema.SearchTarget)
    case row(SearchRow.ID)
  }

  extension View {
    /// focusedPart binds the view's focus to `part` of a search control's `focus`, where a control
    /// hands one, so the control reads the focus standing in it.
    @ViewBuilder
    fileprivate func focusedPart(_ focus: FocusState<SearchPart?>.Binding?, _ part: SearchPart)
      -> some View
    {
      if let focus {
        self.focused(focus, equals: part)
      } else {
        self
      }
    }
  }

  /// SearchRelay hands a search's failures to the handler the control was drawn with last. It is
  /// bound to the main actor, where SwiftUI draws the control and the engine fails.
  @MainActor
  final class SearchRelay {
    private(set) var onError: ((any Error) -> Void)?

    /// hold holds `onError` as the handler a failure reaches.
    func hold(_ onError: ((any Error) -> Void)?) {
      self.onError = onError
    }
  }

  /// SearchField is the search box: a glyph, the field, and the clear button while there is text
  /// to clear, on a chip of the control's ground.
  private struct SearchField: View {
    @Binding var text: String
    var focus: FocusState<SearchPart?>.Binding

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let scheme = themeScheme(colorScheme)
      HStack(spacing: 8) {
        Glyph("search", in: scope.controlGlyphs, size: 18, ink: .foreground)
          .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
        TextField(
          text: $text, prompt: Text(verbatim: scope.word("search.placeholder"))
        ) {
          Text(verbatim: scope.word("search.label"))
        }
        .focused(focus, equals: .box)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.search)
        if !text.isEmpty {
          SearchClearButton(label: scope.word("search.clear")) {
            text = ""
          }
        }
      }
      .padding(.horizontal, 12)
      .frame(minHeight: ControlButton<EmptyView>.side)
      .foregroundStyle(tokenColor(tokens.controlFg, in: scheme))
      .background(tokenColor(tokens.controlBg, in: scheme), in: RoundedRectangle(cornerRadius: 8))
      .shadow(color: shadow(scheme), radius: 2, y: 1)
    }

    private func shadow(_ scheme: ThemeScheme) -> Color {
      themeTokenValue(tokens.controlShadow, in: scheme).first.map(hexColor) ?? .clear
    }
  }

  /// SearchList is what shows under the box: the filter chips, the scope to the visible area where
  /// there is a map, the note of a fall back, a line for each failed branch, `search.error` beside
  /// its retry, the rows, the bar of a round in flight and the empty state, on a panel's surface.
  struct SearchList: View {
    let list: SearchListState
    let isSearching: Bool
    @Binding var filter: SearchFilter
    let isConfined: Binding<Bool>?
    let units: UnitPreferences
    /// focus is the part of the control the keyboard's focus stands in, which each part of the list
    /// it can stand in writes, so the list stays shown while the focus moves through it, or nil for
    /// a list no control shows.
    var focus: FocusState<SearchPart?>.Binding? = nil
    let retry: () -> Void
    let select: (SearchRow) -> Void

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let scheme = themeScheme(colorScheme)
      let dimmed = tokenColor(tokens.dimmed, in: scheme)
      // Its rows scroll on their own, inside a height of their own, so the surface holds them as
      // they are and never scrolls them again.
      PanelSurface(scrolls: false) {
        HStack(spacing: 6) {
          ForEach(SearchFilter.allCases, id: \.self) { chip in
            SearchFilterChip(
              label: SearchControl.filterLabel(chip, in: scope.value), isSelected: chip == filter
            ) {
              filter = chip
            }
            .focusedPart(focus, .filter(chip))
          }
        }
        if let isConfined {
          Toggle(isOn: isConfined) {
            Text(verbatim: scope.word("search.viewportScope")).font(.footnote)
          }
          .tint(tokenColor(tokens.accent, in: scheme))
          .focusedPart(focus, .scope)
        }
        if list.hasFallbackNote {
          HStack(spacing: 6) {
            Glyph("info", in: scope.controlGlyphs, size: 14, ink: .foreground)
            Text(verbatim: scope.word("search.viewportFallback")).font(.footnote)
          }
          .foregroundStyle(dimmed)
        }
        ForEach(list.failed) { section in
          HStack(spacing: 8) {
            Glyph("error", in: scope.controlGlyphs, size: 14, ink: .foreground)
            // The elements' own word, never the API's message, which is English whatever the
            // reader's language and stays on the branch's error for the app to log.
            Text(verbatim: scope.word("search.error")).font(.footnote)
            Spacer(minLength: 8)
            SearchRetryButton(label: scope.word("search.retry"), action: retry)
              .focusedPart(focus, .retry(section.id))
          }
        }
        if !list.rows.isEmpty {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(list.rows) { row in
                SearchResultRow(row: row, units: units, select: select)
                  .focusedPart(focus, .row(row.id))
              }
            }
          }
          .frame(maxHeight: 320)
        }
        if isSearching {
          ProgressView()
            .progressViewStyle(.linear)
            .tint(tokenColor(tokens.accent, in: scheme))
            .accessibilityHidden(true)
        }
        if list.isNothingFound {
          VStack(alignment: .leading, spacing: 4) {
            Glyph("search-empty", in: scope.controlGlyphs, size: 20, ink: .foreground)
            Text(verbatim: scope.word("search.emptyTitle")).font(.subheadline.weight(.semibold))
            Text(verbatim: scope.word("search.emptyDescription")).font(.footnote)
              .foregroundStyle(dimmed)
          }
        }
      }
    }
  }

  /// SearchClearButton empties a search box: the close glyph in a 32-point square, pressed anywhere
  /// in the platform's touch target around it.
  struct SearchClearButton: View {
    let label: String
    let action: () -> Void

    @Environment(\.sharedScope) private var scope

    var body: some View {
      Button(action: action) {
        Glyph("close", in: scope.controlGlyphs, size: 14, ink: .foreground)
          .frame(width: 32, height: 32)
          .focusRing()
          .touchTarget()
      }
      .buttonStyle(ElementButtonStyle(ringsLabel: false))
      .focusEffectDisabled()
      .accessibilityLabel(Text(verbatim: label))
    }
  }

  /// SearchFilterChip is one chip of a search's filters: its word on a capsule 32 points high, in
  /// the accent on the hover ground while it is the filter in force, pressed anywhere in the
  /// platform's touch target around it, and read as selected while it is in force.
  struct SearchFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let scheme = themeScheme(colorScheme)
      Button(action: action) {
        Text(verbatim: label)
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 10)
          .frame(minHeight: 32)
          .foregroundStyle(tokenColor(isSelected ? tokens.accent : tokens.panelFg, in: scheme))
          .background(
            tokenColor(isSelected ? tokens.controlBgHover : tokens.panelBg, in: scheme),
            in: Capsule()
          )
          .overlay(Capsule().strokeBorder(tokenColor(tokens.panelBorder, in: scheme)))
          .focusRing(cornerRadius: 16)
          .touchTarget()
      }
      .buttonStyle(ElementButtonStyle(ringsLabel: false))
      .focusEffectDisabled()
      .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
  }

  /// SearchRetryButton asks a failed branch again: its word in the accent, pressed anywhere in the
  /// platform's touch target around it.
  struct SearchRetryButton: View {
    let label: String
    let action: () -> Void

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      Button(action: action) {
        Text(verbatim: label).font(.footnote.weight(.semibold))
          .foregroundStyle(tokenColor(tokens.accent, in: themeScheme(colorScheme)))
          .frame(minHeight: 32)
          .touchTarget()
      }
      .buttonStyle(ElementButtonStyle())
      .focusEffectDisabled()
    }
  }

  /// SearchResultRow is one row of a search's list: its title, the runs the query matched set
  /// strong, and its second line, pressed as a whole, the platform's touch target high.
  struct SearchResultRow: View {
    let row: SearchRow
    let units: UnitPreferences
    let select: (SearchRow) -> Void

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let dimmed = tokenColor(tokens.dimmed, in: themeScheme(colorScheme))
      Button {
        select(row)
      } label: {
        VStack(alignment: .leading, spacing: 2) {
          Text(SearchControl.title(row)).lineLimit(1)
          secondaryLine.font(.caption).lineLimit(1).foregroundStyle(dimmed)
        }
        .frame(maxWidth: .infinity, minHeight: ControlButton<EmptyView>.side, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(ElementButtonStyle())
      .focusEffectDisabled()
    }

    /// secondaryLine is the row's second line: its sentence; an itinerary's distance, then its
    /// ascent behind an ascent's arrow; or a collection's count behind an itinerary's glyph.
    @ViewBuilder
    private var secondaryLine: some View {
      switch row.secondary {
      case .text(let text)?:
        Text(verbatim: text)
      case .metric(let distance, let ascent)?:
        HStack(spacing: 4) {
          Text(verbatim: formatDistance(distance, units: units) + " \u{B7}")
          Glyph(
            "ascent", in: scope.controlGlyphs, size: 12, ink: .foreground,
            label: scope.word("profile.ascent"))
          Text(verbatim: formatElevation(ascent.map(Double.init), units: units))
        }
      case .count(let itineraries)?:
        HStack(spacing: 4) {
          Glyph(
            "itinerary", in: scope.controlGlyphs, size: 12, ink: .foreground,
            label: scope.word("search.categoryItineraries"))
          Text(verbatim: itineraries.map(String.init) ?? "")
        }
      case nil:
        EmptyView()
      }
    }
  }
#endif
