import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// styleThemeTokens answers the value the case's `token` reads under its `scheme`, with the
  /// values its `overrides` state set on a copy of the standard tokens as a consumer sets them:
  /// each token whole, a token of its value alone, which stands in both schemes. A token is reached
  /// by its member, the runner's table of the contract's names, which the elements' data suite holds
  /// to the printed one.
  static let styleThemeTokens = Runner(id: "geo.style.theme-tokens", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    guard let scheme = ThemeScheme(rawValue: try input.string(at: "scheme")) else {
      throw FixtureError(description: "the case's `scheme` is neither light nor dark")
    }
    var tokens = ElementTokens.standard
    guard let overrides = input["overrides"]?.members else {
      throw FixtureError(description: "the case's `overrides` is not an object")
    }
    for override in overrides {
      try GeoControlFixtures.state(override.value, for: override.key, on: &tokens)
    }
    return .value(
      try GeoControlFixtures.value(
        of: try input.string(at: "token"), in: tokens, under: scheme))
  }

  /// i18nNestedScope answers the innermost of the case's `scopes`, each nested in the one before
  /// it and the outermost in the standard scope, which holds the elements' words in every language
  /// the table holds: its language, its locale, its two zoom words and the names of its two glyph
  /// sets (`GeoControlFixtures.glyphSet(named:)`).
  static let i18nNestedScope = Runner(id: "geo.i18n.nested-scope", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    var scope = ElementsScope.standard
    for written in try fixtureCase.input.array(at: "scopes") {
      scope = scopeOf(scope, stating: try GeoControlFixtures.statement(written))
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "glyphs",
          value: .object([
            OrderedJSON.Member(
              key: "controls", value: .string(GeoControlFixtures.nameOf(scope.controlGlyphs))),
            OrderedJSON.Member(
              key: "markers", value: .string(GeoControlFixtures.nameOf(scope.markerGlyphs))),
          ])),
        OrderedJSON.Member(key: "language", value: .string(scope.language.rawValue)),
        OrderedJSON.Member(key: "locale", value: .string(scope.locale)),
        OrderedJSON.Member(
          key: "words",
          value: .object([
            OrderedJSON.Member(
              key: "controls",
              value: .object([
                OrderedJSON.Member(key: "zoomIn", value: .string(scope.word("controls.zoomIn"))),
                OrderedJSON.Member(
                  key: "zoomOut", value: .string(scope.word("controls.zoomOut"))),
              ]))
          ])),
      ]))
  }

  /// i18nCountedWords answers the text the case's `word` of the elements' words, resolved for its
  /// `language`, takes: a counted word for its `count`, or a template filled with its `value`, the
  /// case's own `template` standing in place of the table's text where it states one, as a host's
  /// words override a word.
  static let i18nCountedWords = Runner(id: "geo.i18n.counted-words", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let language = RestSchema.Language(rawValue: try input.string(at: "language"))
    let path = try input.string(at: "word")
    guard
      var word = GeoControlFixtures.word(
        at: path, in: resolveBundle(.elements, language: language))
    else { throw FixtureError(description: "the words hold nothing at `\(path)`") }
    // The forms a host's own words hold for a counted word stand in for the table's.
    if let forms = input["forms"] {
      guard forms.members != nil else {
        throw FixtureError(description: "`forms` is not an object of forms")
      }
      word = GeoFixtures.json(forms)
    }
    if let count = try input.optionalInteger(at: "count") {
      guard let text = countedText(word, count: count, language: language) else {
        throw FixtureError(description: "`\(path)` is no counted word")
      }
      return .value(.string(text))
    }
    guard case .string(let table) = word else {
      throw FixtureError(description: "`\(path)` is no template")
    }
    let template = try input.optionalString(at: "template") ?? table
    // A template handed several values takes each by its placeholder's name.
    if let written = input["values"] {
      guard let members = written.members else {
        throw FixtureError(description: "`values` is not an object of values")
      }
      var values: [String: String] = [:]
      for member in members {
        guard let value = member.value.stringValue else {
          throw FixtureError(description: "the value `\(member.key)` is no text")
        }
        values[member.key] = value
      }
      return .value(.string(filledText(template, values: values)))
    }
    return .value(.string(filledText(template, value: try input.string(at: "value"))))
  }

  /// layersSelection plays the case's `steps` over one selection driving a map that answers every
  /// command at once, the catalogue it reads as it starts held until the `catalogue` step lands it,
  /// and answers every command the map was given and what the selection holds after each step.
  static let layersSelection = Runner(id: "geo.layers.selection", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playSelection(fixtureCase.input)
  }

  /// layersSelectionOutcome plays the case's `steps` over one selection and the named maps of its
  /// `maps`, every command and catalogue read held until a step settles it, numbered across maps, a
  /// read landed by `catalogue` and failed by `fail`, and answers every command a map was given and
  /// what the selection holds after each step, whether a refusal stands among it.
  static let layersSelectionOutcome = Runner(
    id: "geo.layers.selection-outcome", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playOutcome(fixtureCase.input)
  }

  /// layersSelectionInstant plays the case's `steps` over one selection and the named maps of its
  /// `maps`, as `geo.layers.selection-outcome`'s runner plays them, with `instant` pinning the
  /// instant `at` names, none where it is null, and a `Date` of no number where it names no
  /// instant, which Swift's `Date` holds and the selection reads as none, and answers every command
  /// a map was given, a pin's instant in milliseconds, and the instant, the overlay and whether a
  /// refusal stands after each step.
  static let layersSelectionInstant = Runner(
    id: "geo.layers.selection-instant", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playOutcome(fixtureCase.input, shown: GeoControlFixtures.instantShown)
  }

  @MainActor
  private static func playSelection(_ input: OrderedJSON) async throws -> RunnerOutcome {
    guard let written = input["catalogue"] else {
      throw FixtureError(description: "the case names no `catalogue`")
    }
    let maps = GeoControlFixtures.SelectionMaps(
      catalogue: try GeoControlFixtures.catalogueBySlug(written), answersAtOnce: true)
    let map = maps.map("map", shows: try input.optionalString(at: "shows"))
    let engine = LayersSelectionEngine(map: map)
    var snapshots: [OrderedJSON] = []
    func settle() async {
      await GeoControlFixtures.settle {
        [GeoControlFixtures.selectionShown(engine.state, refusal: false), maps.progress]
      }
    }
    do {
      await settle()
      for step in try input.array(at: "steps") {
        switch try step.string(at: "step") {
        case "catalogue": try maps.land(0)
        case "shows": map.terrain = try step.optionalString(at: "terrain")
        case "terrain": engine.setTerrain(try step.string(at: "slug"))
        case "overlay": engine.setOverlay(try step.optionalString(at: "slug"))
        case "enrichment": engine.toggleEnrichment(try step.string(at: "slug"))
        case let other: throw FixtureError(description: "`\(other)` is no step")
        }
        await settle()
        snapshots.append(GeoControlFixtures.selectionShown(engine.state, refusal: false))
      }
    } catch {
      engine.close()
      maps.release()
      throw error
    }
    engine.close()
    maps.release()
    return .value(
      .object([
        OrderedJSON.Member(key: "calls", value: maps.written(naming: false)),
        OrderedJSON.Member(key: "snapshots", value: .array(snapshots)),
      ]))
  }

  @MainActor
  private static func playOutcome(
    _ input: OrderedJSON,
    shown: (LayersSelection) -> OrderedJSON = {
      GeoControlFixtures.selectionShown($0, refusal: true)
    }
  ) async throws -> RunnerOutcome {
    guard let written = input["catalogue"], let named = input["maps"]?.members else {
      throw FixtureError(description: "the case names no `catalogue` or no `maps`")
    }
    let maps = GeoControlFixtures.SelectionMaps(
      catalogue: try GeoControlFixtures.catalogueBySlug(written), answersAtOnce: false)
    let engine = LayersSelectionEngine()
    var snapshots: [OrderedJSON] = []
    do {
      for step in try input.array(at: "steps") {
        switch try step.string(at: "step") {
        case "map":
          guard let name = try step.optionalString(at: "map") else {
            engine.configure(map: nil)
            break
          }
          guard let shown = named.first(where: { $0.key == name })?.value else {
            throw FixtureError(description: "the case names no map `\(name)`")
          }
          engine.configure(map: maps.map(name, shows: try shown.optionalString(at: "shows")))
        case "catalogue": try maps.land(try step.integer(at: "read"))
        case "fail": try maps.fail(try step.integer(at: "read"))
        case "terrain": engine.setTerrain(try step.string(at: "slug"))
        case "overlay": engine.setOverlay(try step.optionalString(at: "slug"))
        case "enrichment": engine.toggleEnrichment(try step.string(at: "slug"))
        case "instant":
          engine.setInstant(
            try step.optionalString(at: "at").map {
              parseTimestamp($0) ?? Date(timeIntervalSince1970: .nan)
            })
        case "accept": try maps.settle(try step.integer(at: "call"), refused: false)
        case "refuse": try maps.settle(try step.integer(at: "call"), refused: true)
        case let other: throw FixtureError(description: "`\(other)` is no step")
        }
        await GeoControlFixtures.settle { [shown(engine.state), maps.progress] }
        snapshots.append(shown(engine.state))
      }
    } catch {
      engine.close()
      maps.release()
      throw error
    }
    engine.close()
    maps.release()
    return .value(
      .object([
        OrderedJSON.Member(key: "calls", value: maps.written(naming: true)),
        OrderedJSON.Member(key: "snapshots", value: .array(snapshots)),
      ]))
  }
}
