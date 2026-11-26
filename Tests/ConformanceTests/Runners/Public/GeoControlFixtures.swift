import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

/// GeoControlFixtures reads what the family 8d fixtures write, the controls' and the panels', into
/// the values Geo takes, and writes Geo's answers back in the fixtures' shapes.
enum GeoControlFixtures {
  /// settle lets what a step set going come to rest, which is how a script waits for an engine's
  /// answers to land with no clock: the engines, their maps and their tasks all run on the main
  /// actor, a map's command reached through the runtime's hop to a protocol's requirement, so the
  /// script reads what it reports until it stands still (`Quiescence`).
  @MainActor
  static func settle<Observed: Equatable>(observing observed: () -> Observed) async {
    await Quiescence.settle(observing: observed)
  }

  // MARK: - Tokens

  /// colorTokens is each colour token's member, by the name the contract's table gives it, as a
  /// consumer reaches it: a member of `ElementTokens` set on a copy of `standard`. Conformance's
  /// own suite holds the names and the members to the printed table's.
  static var colorTokens: [String: WritableKeyPath<ElementTokens, ThemeToken<HexColor>>] {
    [
      "accent": \.accent, "control-bg": \.controlBg, "control-bg-hover": \.controlBgHover,
      "control-fg": \.controlFg, "control-fg-disabled": \.controlFgDisabled, "dimmed": \.dimmed,
      "focus-ring": \.focusRing, "panel-bg": \.panelBg, "panel-border": \.panelBorder,
      "panel-fg": \.panelFg,
      "profile-cursor": \.profileCursor, "profile-grid-color": \.profileGridColor,
      "profile-lit-fill": \.profileLitFill, "profile-navigator-handle": \.profileNavigatorHandle,
      "profile-navigator-veil": \.profileNavigatorVeil, "profile-tooltip-bg": \.profileTooltipBg,
      "profile-tooltip-fg": \.profileTooltipFg, "profile-waypoint-color": \.profileWaypointColor,
      "profile-waypoint-line": \.profileWaypointLine, "table-border": \.tableBorder,
      "table-row-hover": \.tableRowHover, "table-spark-base": \.tableSparkBase,
      "tooltip-bg": \.tooltipBg, "tooltip-fg": \.tooltipFg,
      "waypoint-card-mark-color": \.waypointCardMarkColor,
      "waypoint-card-mark-fg": \.waypointCardMarkFg,
    ]
  }

  /// shadowTokens is each shadow token's member, by the name the contract's table gives it.
  static var shadowTokens: [String: WritableKeyPath<ElementTokens, ThemeToken<[HexColor]>>] {
    ["control-shadow": \.controlShadow, "profile-tooltip-shadow": \.profileTooltipShadow]
  }

  /// dashTokens is each dash token's member, by the name the contract's table gives it.
  static var dashTokens: [String: WritableKeyPath<ElementTokens, ThemeToken<[Double]>>] {
    ["profile-cursor-dash": \.profileCursorDash]
  }

  /// state sets the value a consumer states for the token `name` on `tokens`, as a consumer does:
  /// the token set whole to a token of that value alone.
  static func state(_ value: OrderedJSON, for name: String, on tokens: inout ElementTokens)
    throws(FixtureError)
  {
    if let path = colorTokens[name] {
      tokens[keyPath: path] = ThemeToken(light: try color(value, naming: name))
    } else if let path = shadowTokens[name] {
      var colors: [HexColor] = []
      for element in value.elements ?? [] {
        colors.append(try color(element, naming: name))
      }
      tokens[keyPath: path] = ThemeToken(light: colors)
    } else if let path = dashTokens[name] {
      tokens[keyPath: path] = ThemeToken(light: try value.numberList(naming: name))
    } else {
      throw FixtureError(description: "`\(name)` is no token of the table")
    }
  }

  /// value is the value the token `name` of `tokens` reads under `scheme`, written as the table
  /// writes one: a colour `{hex}`, its `opacity` beside it only where it is translucent, a shadow
  /// as its colours and a dash as its lengths.
  static func value(of name: String, in tokens: ElementTokens, under scheme: ThemeScheme)
    throws(FixtureError) -> OrderedJSON
  {
    if let path = colorTokens[name] {
      return written(themeTokenValue(tokens[keyPath: path], in: scheme))
    }
    if let path = shadowTokens[name] {
      return .array(themeTokenValue(tokens[keyPath: path], in: scheme).map(written))
    }
    if let path = dashTokens[name] {
      return GeoFixtures.numbers(themeTokenValue(tokens[keyPath: path], in: scheme))
    }
    throw FixtureError(description: "`\(name)` is no token of the table")
  }

  private static func color(_ value: OrderedJSON, naming name: String) throws(FixtureError)
    -> HexColor
  {
    guard let hex = value["hex"]?.stringValue else {
      throw FixtureError(description: "the value of `\(name)` is no colour")
    }
    return HexColor(hex: hex, opacity: try value.optionalNumber(at: "opacity") ?? 1)
  }

  private static func written(_ color: HexColor) -> OrderedJSON {
    var members = [OrderedJSON.Member(key: "hex", value: .string(color.hex))]
    if color.opacity != 1 {
      members.append(OrderedJSON.Member(key: "opacity", value: .number(color.opacity)))
    }
    return .object(members)
  }

  // MARK: - Words and scopes

  /// word is the word `words` holds at the dotted `path`, or nil where it holds none there.
  static func word(at path: String, in words: [String: JSONValue]) -> JSONValue? {
    var keys = path.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    guard !keys.isEmpty else { return nil }
    let last = keys.removeLast()
    var section = words
    for key in keys {
      guard case .object(let inner)? = section[key] else { return nil }
      section = inner
    }
    return section[last]
  }

  /// statement reads a statement of a nested scope as a fixture writes it: a `language`, a
  /// `locale`, the `words` it states, keyed by section or by language, and the glyph sets its
  /// controls and its markers draw with, by their names (`glyphSet(named:)`).
  static func statement(_ written: OrderedJSON) throws(FixtureError) -> ElementsScopeStatement {
    var statement = ElementsScopeStatement()
    statement.language = try written.optionalString(at: "language").map(
      RestSchema.Language.init(rawValue:))
    statement.locale = try written.optionalString(at: "locale")
    if let words = written["words"], !words.isNull {
      guard let overrides = wordOverridesOf(try GeoFixtures.jsonObject(words, naming: "words"))
      else {
        throw FixtureError(description: "the words name a language and a section together")
      }
      statement.words = overrides
    }
    statement.controlGlyphs = try written.optionalString(at: "controlGlyphs").map(glyphSet(named:))
    statement.markerGlyphs = try written.optionalString(at: "markerGlyphs").map(glyphSet(named:))
    return statement
  }

  /// glyphSet is the set a fixture names: the bundled control set, `bundled-controls`, the bundled
  /// marker set, `bundled-markers`, or a licensed set of the host's own under any other name, which
  /// holds a glyph no rule here draws.
  static func glyphSet(named name: String) throws(FixtureError) -> GlyphSet {
    switch name {
    case "bundled-controls": return .control
    case "bundled-markers": return .marker
    default:
      guard
        let set = GlyphSet(name: name, paint: .stroke, markup: ["zoom-in": #"<path d="M0 0"/>"#])
      else { throw FixtureError(description: "no set can be named `\(name)`") }
      return set
    }
  }

  /// nameOf is the name a fixture gives `set`.
  static func nameOf(_ set: GlyphSet) -> String {
    if set == .control { return "bundled-controls" }
    if set == .marker { return "bundled-markers" }
    return set.name
  }

  // MARK: - The layers catalogue

  /// catalogueBySlug builds the catalogue a selection fixture names by slug: its terrains, one
  /// classic category, `conditions`, holding the classic overlays, and the category whose overlays
  /// stack holding the enrichments, every other member a placeholder no selection reads.
  static func catalogueBySlug(_ written: OrderedJSON) throws(FixtureError) -> TileSchema.Layers {
    guard let overlays = written["overlays"] else {
      throw FixtureError(description: "the catalogue names no `overlays`")
    }
    var catalogue = GeoTileFixtures.layers([
      GeoTileFixtures.category(
        "conditions",
        children: try GeoFixtures.textList(overlays, at: "classic").map {
          GeoTileFixtures.overlay($0, id: $0)
        }),
      GeoTileFixtures.category(
        enrichmentCategorySlug,
        children: try GeoFixtures.textList(overlays, at: "enrichment").map {
          GeoTileFixtures.overlay($0, id: $0)
        }),
    ])
    catalogue.terrains = try GeoFixtures.textList(written, at: "terrains").map {
      terrain($0, locales: GeoTileFixtures.noLocales)
    }
    return catalogue
  }

  /// catalogueOf builds the catalogue a picker fixture writes: its terrains and its categories,
  /// each entry by its slug and the names its `locales` hold, every other member a placeholder no
  /// picker reads.
  static func catalogueOf(_ written: OrderedJSON) throws(FixtureError) -> TileSchema.Layers {
    var categories: [TileSchema.CategoryOverlays] = []
    for category in try written.array(at: "overlays") {
      var children: [TileSchema.Overlay] = []
      for child in try category.array(at: "children") {
        let slug = try child.string(at: "slug")
        var overlay = GeoTileFixtures.overlay(slug, id: slug)
        overlay.locales = try locales(child)
        children.append(overlay)
      }
      var built = GeoTileFixtures.category(try category.string(at: "slug"), children: children)
      built.locales = try locales(category)
      categories.append(built)
    }
    var catalogue = GeoTileFixtures.layers(categories)
    for written in try written.array(at: "terrains") {
      catalogue.terrains.append(
        terrain(try written.string(at: "slug"), locales: try locales(written)))
    }
    return catalogue
  }

  /// terrain builds the terrain `slug` names, under `locales`, its variants placeholders no rule
  /// here reads.
  private static func terrain(_ slug: String, locales: TileSchema.Locales) -> TileSchema.Terrain {
    let variant = TileSchema.TerrainVariantConfig(
      style: TileSchema.TerrainVariantAsStyle(url: URI(URL(fileURLWithPath: "/\(slug)/style"))),
      tiles: TileSchema.TerrainVariantAsTiles(
        size: .size512, url: URI(URL(fileURLWithPath: "/\(slug)/tiles"))))
    return TileSchema.Terrain(
      id: slug, locales: locales, slug: slug,
      variants: TileSchema.TerrainVariants(dark: variant, light: variant))
  }

  /// locales reads the names an entry's `locales` hold, keyed by language.
  private static func locales(_ entry: OrderedJSON) throws(FixtureError) -> TileSchema.Locales {
    guard let written = entry["locales"], let languages = written.members else {
      throw FixtureError(description: "an entry has no `locales` object")
    }
    func strings(_ language: String) -> TileSchema.LocaleMap? {
      guard let names = languages.first(where: { $0.key == language })?.value.members else {
        return nil
      }
      return Dictionary(
        names.map { ($0.key, $0.value.stringValue) }, uniquingKeysWith: { _, last in last })
    }
    return TileSchema.Locales(
      de: strings("de"), en: strings("en"), es: strings("es"), fr: strings("fr"),
      it: strings("it"), ja: strings("ja"), zh: strings("zh"))
  }

  // MARK: - The maps a selection drives

  /// SelectionMaps stands for the maps a layers selection drives, each named, every command any of
  /// them is given and every catalogue read numbered from 0 in the order sent, across maps, and
  /// held until a step settles it, or answered at once where `answersAtOnce` says so.
  @MainActor
  final class SelectionMaps {
    /// Map is one map the selection may drive, which records into the maps' ledger.
    @MainActor
    final class Map: LayersSelectionTarget {
      let name: String
      var terrain: String?
      unowned let maps: SelectionMaps

      init(name: String, shows terrain: String?, maps: SelectionMaps) {
        self.name = name
        self.terrain = terrain
        self.maps = maps
      }

      func loadLayers() async throws -> TileSchema.Layers {
        try await withCheckedThrowingContinuation { continuation in
          maps.reads.append((name, continuation))
        }
      }

      func setTerrain(_ slug: String?) async throws {
        try await maps.command(self, named: "terrain", slug: slug)
      }
      func setOverlay(_ slug: String) async throws {
        try await maps.command(self, named: "overlay", slug: slug)
      }
      func clearOverlay() async throws { try await maps.command(self, named: "overlay", slug: nil) }
      func addEnrichment(_ slug: String) async throws {
        try await maps.command(self, named: "add-enrichment", slug: slug)
      }
      func removeEnrichment(_ slug: String) async throws {
        try await maps.command(self, named: "remove-enrichment", slug: slug)
      }
      func setInstant(_ instant: Date?) async throws {
        try await maps.command(
          self, named: "instant",
          member: OrderedJSON.Member(
            key: "instant", value: GeoControlFixtures.millisecondsOf(instant)))
      }
    }

    /// Refused is what a map a step refuses throws.
    struct Refused: Error {}

    let catalogue: TileSchema.Layers
    let answersAtOnce: Bool
    private var named: [String: Map] = [:]
    fileprivate var reads:
      [(map: String, answer: CheckedContinuation<TileSchema.Layers, any Error>?)] =
        []
    /// calls is every command a map was given, its map, its name and what it asks for: an
    /// overlay's or an enrichment's slug, or an instant.
    private var calls: [(map: String, command: String, asked: OrderedJSON.Member)] = []
    private var answers: [CheckedContinuation<Void, any Error>?] = []

    init(catalogue: TileSchema.Layers, answersAtOnce: Bool) {
      self.catalogue = catalogue
      self.answersAtOnce = answersAtOnce
    }

    /// map is the map `name` names, made the first time it is named, showing `terrain`.
    func map(_ name: String, shows terrain: String?) -> Map {
      if let held = named[name] { return held }
      let made = Map(name: name, shows: terrain, maps: self)
      named[name] = made
      return made
    }

    /// land lands the catalogue read `read`.
    func land(_ read: Int) throws(FixtureError) {
      guard reads.indices.contains(read), let answer = reads[read].answer else {
        throw FixtureError(description: "the catalogue read \(read) was never sent, or answered")
      }
      reads[read].answer = nil
      answer.resume(returning: catalogue)
    }

    /// fail fails the catalogue read `read`.
    func fail(_ read: Int) throws(FixtureError) {
      guard reads.indices.contains(read), let answer = reads[read].answer else {
        throw FixtureError(description: "the catalogue read \(read) was never sent, or answered")
      }
      reads[read].answer = nil
      answer.resume(throwing: Refused())
    }

    /// settle lets the command `call` succeed, or fail where `refused` says so.
    func settle(_ call: Int, refused: Bool) throws(FixtureError) {
      guard answers.indices.contains(call), let answer = answers[call] else {
        throw FixtureError(description: "the command \(call) was never sent, or answered")
      }
      answers[call] = nil
      if refused {
        answer.resume(throwing: Refused())
      } else {
        answer.resume()
      }
    }

    /// release fails everything still held, so no task waits for ever once a case ends.
    func release() {
      for index in reads.indices {
        reads[index].answer?.resume(throwing: Refused())
        reads[index].answer = nil
      }
      for index in answers.indices {
        answers[index]?.resume(throwing: Refused())
        answers[index] = nil
      }
    }

    /// progress is what a script reads of the maps to know a step has come to rest: every command
    /// given, and every read and command sent and still held.
    var progress: OrderedJSON {
      .array([
        written(naming: true), .number(Double(reads.count)),
        .number(Double(reads.filter { $0.answer != nil }.count)), .number(Double(answers.count)),
        .number(Double(answers.filter { $0 != nil }.count)),
      ])
    }

    /// written is every command a map was given, as the fixtures write one.
    func written(naming: Bool) -> OrderedJSON {
      .array(
        calls.map { call in
          var members = [
            OrderedJSON.Member(key: "command", value: .string(call.command)), call.asked,
          ]
          if naming {
            members.append(OrderedJSON.Member(key: "map", value: .string(call.map)))
          }
          return .object(members)
        })
    }

    fileprivate func command(_ map: Map, named command: String, slug: String?) async throws {
      try await self.command(
        map, named: command,
        member: OrderedJSON.Member(key: "slug", value: slug.map { .string($0) } ?? .null))
    }

    fileprivate func command(_ map: Map, named command: String, member: OrderedJSON.Member)
      async throws
    {
      calls.append((map.name, command, member))
      guard !answersAtOnce else {
        answers.append(nil)
        return
      }
      try await withCheckedThrowingContinuation { continuation in
        answers.append(continuation)
      }
    }
  }

  /// millisecondsOf writes an instant in milliseconds from the epoch, as the fixtures write one, or
  /// `null` for none.
  static func millisecondsOf(_ instant: Date?) -> OrderedJSON {
    instant.map { .number(($0.timeIntervalSince1970 * 1000).rounded()) } ?? .null
  }

  /// instantShown writes what a selection holds of its instant as the fixtures do: the instant
  /// pinned, its overlay, and whether a refusal stands.
  static func instantShown(_ selection: LayersSelection) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "instant", value: millisecondsOf(selection.instant)),
      OrderedJSON.Member(key: "overlay", value: selection.overlay.map { .string($0) } ?? .null),
      OrderedJSON.Member(key: "refused", value: .bool(selection.refusal != nil)),
    ])
  }

  /// selectionShown writes what a selection holds as the fixtures do: its terrain, its overlay and
  /// its enrichments, and whether a refusal stands where `refusal` asks for it.
  static func selectionShown(_ selection: LayersSelection, refusal: Bool) -> OrderedJSON {
    var members = [
      OrderedJSON.Member(key: "enrichments", value: GeoFixtures.texts(selection.enrichments)),
      OrderedJSON.Member(key: "overlay", value: selection.overlay.map { .string($0) } ?? .null),
      OrderedJSON.Member(key: "terrain", value: selection.terrain.map { .string($0) } ?? .null),
    ]
    if refusal {
      members.append(OrderedJSON.Member(key: "refused", value: .bool(selection.refusal != nil)))
    }
    return .object(members)
  }
}
