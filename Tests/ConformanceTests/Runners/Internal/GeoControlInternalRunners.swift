import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// controlsGeolocateState plays the case's `steps` over one locate control and the maps it
  /// names, every permission read and every fix held until a step settles it, numbered across maps,
  /// and answers the map each read and each fix was sent to and what the control shows after each
  /// step, with the failed fixes reported so far.
  ///
  /// A permission read answers whether the standing permission refuses a fix: `denied` does, and
  /// `granted`, `prompt` and `unknown` do not; `fails` throws. A fix refused for any reason throws.
  /// The rule is the control's own, which a consumer observes as a control's word, so it is
  /// reached as an internal.
  static let controlsGeolocateState = Runner(
    id: "geo.controls.geolocate-state", table: .internal
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playGeolocate(try fixtureCase.input.array(at: "steps"))
  }

  /// layersPickerRows answers the sections a layers picker lists over the case's `catalogue`, or
  /// none still to be read, and `selection` in its `language`, its `locked` entries locked, the
  /// overlays opening on its `picked` category, the time offered where its `time` says so, and what
  /// a press on its `press` asks for. A section's heading is the path of its word, as the fixture
  /// names it, and the overlays' section states its `categories`. The category whose overlays stack
  /// and the overlay the points-of-interest picker drives are held to the ones Geo publishes.
  static let layersPickerRows = Runner(id: "geo.layers.picker-rows", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "enrichmentCategory": .string(enrichmentCategorySlug),
        "poisOverlay": .string(poisOverlaySlug),
      ])
    let input = fixtureCase.input
    guard let selected = input["selection"] else {
      throw FixtureError(description: "the case names no `selection`")
    }
    let catalogue = input["catalogue"].flatMap { $0.isNull ? nil : $0 }
    let locked = try GeoFixtures.textList(input, at: "locked")
    let selection = LayersSelection(
      catalogue: try catalogue.map { written throws(FixtureError) in
        try GeoControlFixtures.catalogueOf(written)
      },
      terrain: try selected.optionalString(at: "terrain"),
      overlay: try selected.optionalString(at: "overlay"),
      enrichments: try GeoFixtures.textList(selected, at: "enrichments"))
    let sections = layersPanelSections(
      selection, language: try input.string(at: "language"),
      isLocked: { slug in locked.contains { sameText($0, slug) } },
      picked: try input.optionalString(at: "picked"), offersTime: try input.flag(at: "time"))
    var pressed = OrderedJSON.null
    if let press = try input.optionalString(at: "press") {
      guard
        let section = sections.first(where: { $0.rows.contains { sameText($0.slug, press) } }),
        let row = section.rows.first(where: { sameText($0.slug, press) })
      else { throw FixtureError(description: "no row of `\(press)` stands") }
      switch layersPanelPress(section.choice, row: row) {
      case .locked(let slug):
        pressed = .object([OrderedJSON.Member(key: "locked", value: .string(slug))])
      case .command(let choice, let slug):
        pressed = .object([
          OrderedJSON.Member(key: "command", value: .string(choice.rawValue)),
          OrderedJSON.Member(key: "slug", value: .string(slug)),
        ])
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "pressed", value: pressed),
        OrderedJSON.Member(key: "sections", value: .array(sections.map(sectionWritten))),
      ]))
  }

  /// layersPoiRows answers the rows a points-of-interest picker offers over the case's `drawn`
  /// keys, its `hidden` ones hidden, curated by its `keys` or its `groups`, each group labelled by
  /// its id, the master row, and whether the picker notes that the overlay draws nothing at the
  /// case's `zoom` below its `minZoom`.
  static let layersPoiRows = Runner(id: "geo.layers.poi-rows", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let hidden = try GeoFixtures.textList(input, at: "hidden")
    var groups: [POIPanelGroup]?
    if let written = input["groups"], !written.isNull {
      var read: [POIPanelGroup] = []
      for group in written.elements ?? [] {
        let id = try group.string(at: "id")
        read.append(
          POIPanelGroup(id: id, label: id, keys: try GeoFixtures.textList(group, at: "keys")))
      }
      groups = read
    }
    var keys: [String]?
    if let written = input["keys"], !written.isNull {
      keys = try GeoFixtures.textList(input, at: "keys")
    }
    let offer = poiPanelRows(
      drawn: try GeoFixtures.textList(input, at: "drawn"),
      isKeyVisible: { key in !hidden.contains { sameText($0, key) } }, keys: keys, groups: groups)
    let zoom = try input.number(at: "zoom")
    let isNoted = !(zoom >= poiPanelNoteZoom(try input.optionalNumber(at: "minZoom")))
    return .value(
      .object([
        OrderedJSON.Member(key: "master", value: .bool(offer.isAnyVisible)),
        OrderedJSON.Member(key: "note", value: .bool(isNoted)),
        OrderedJSON.Member(
          key: "rows",
          value: .array(
            offer.rows.map { row in
              .object([
                OrderedJSON.Member(key: "id", value: .string(row.id)),
                OrderedJSON.Member(key: "keys", value: GeoFixtures.texts(row.keys)),
                OrderedJSON.Member(key: "on", value: .bool(row.isVisible)),
              ])
            })),
      ]))
  }

  /// unitsPreferenceChoices answers what a preferences picker offers over the case's `preferences`
  /// and what a press on its `press` asks for: the set it reports and the language the map
  /// relabels in. A word is named by its key in the `preferences` section, as the fixture names it.
  static let unitsPreferenceChoices = Runner(
    id: "geo.units.preference-choices", table: .internal
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    guard let written = input["preferences"] else {
      throw FixtureError(description: "the case names no `preferences`")
    }
    let preferences = UnitPreferences(
      language: try written.string(at: "language"),
      length: RestSchema.UnitLength(rawValue: try written.string(at: "length")),
      pace: RestSchema.UnitPace(rawValue: try written.string(at: "pace")),
      slope: RestSchema.UnitSlope(rawValue: try written.string(at: "slope")),
      temperature: RestSchema.UnitTemperature(rawValue: try written.string(at: "temperature")))
    var reported = OrderedJSON.null
    var relabel = OrderedJSON.null
    if let press = input["press"], !press.isNull {
      let value = try preferenceValue(
        field: try press.string(at: "field"), value: try press.string(at: "value"))
      let pressed = preferencePress(preferences, pressing: value)
      reported = preferencesWritten(pressed.next)
      relabel = pressed.relabel.map { .string($0.rawValue) } ?? .null
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "choices", value: .array(preferenceChoices(preferences).map(choiceWritten))),
        OrderedJSON.Member(key: "relabel", value: relabel),
        OrderedJSON.Member(key: "reported", value: reported),
      ]))
  }

  // MARK: - The locate control's script

  /// LocateMaps stands for the maps a locate control stands over, each named, every permission read
  /// and every fix numbered from 0 in the order sent, across maps, and held until a step settles it.
  @MainActor
  private final class LocateMaps {
    /// Map is one map the control may stand over, which records into the maps' ledger.
    @MainActor
    final class Map: GeolocateControlTarget {
      let name: String
      unowned let maps: LocateMaps

      init(name: String, maps: LocateMaps) {
        self.name = name
        self.maps = maps
      }

      func locate() async throws -> [Double] {
        try await withCheckedThrowingContinuation { continuation in
          maps.fixes.append((name, continuation))
        }
      }

      func isLocationRefused() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
          maps.reads.append((name, continuation))
        }
      }
    }

    /// Refused is what a fix refused, or a read that fails, throws, naming the reason.
    struct Refused: Error {
      let reason: String
    }

    private var named: [String: Map] = [:]
    var reads: [(map: String, answer: CheckedContinuation<Bool, any Error>?)] = []
    var fixes: [(map: String, answer: CheckedContinuation<[Double], any Error>?)] = []

    /// progress is what a script reads of the maps to know a step has come to rest: every read and
    /// fix sent, and those still held.
    var progress: [Int] {
      [
        reads.count, reads.filter { $0.answer != nil }.count, fixes.count,
        fixes.filter { $0.answer != nil }.count,
      ]
    }

    func map(_ name: String) -> Map {
      if let held = named[name] { return held }
      let made = Map(name: name, maps: self)
      named[name] = made
      return made
    }

    func answer(read: Int, with answer: String) throws(FixtureError) {
      guard reads.indices.contains(read), let held = reads[read].answer else {
        throw FixtureError(description: "the permission read \(read) was never sent, or answered")
      }
      reads[read].answer = nil
      switch answer {
      case "denied": held.resume(returning: true)
      case "granted", "prompt", "unknown": held.resume(returning: false)
      case "fails": held.resume(throwing: Refused(reason: "the seam could not say"))
      default:
        held.resume(returning: false)
        throw FixtureError(description: "`\(answer)` is no permission")
      }
    }

    func settle(fix: Int, with answer: String) throws(FixtureError) {
      guard fixes.indices.contains(fix), let held = fixes[fix].answer else {
        throw FixtureError(description: "the fix \(fix) was never sent, or answered")
      }
      fixes[fix].answer = nil
      switch answer {
      case "located": held.resume(returning: [6.86, 45.83])
      case "denied", "no_api", "unavailable": held.resume(throwing: Refused(reason: answer))
      default:
        held.resume(throwing: Refused(reason: answer))
        throw FixtureError(description: "`\(answer)` is no fix's answer")
      }
    }

    /// release answers everything still held, so no task waits for ever once a case ends.
    func release() {
      for index in reads.indices {
        reads[index].answer?.resume(returning: false)
        reads[index].answer = nil
      }
      for index in fixes.indices {
        fixes[index].answer?.resume(throwing: Refused(reason: "released"))
        fixes[index].answer = nil
      }
    }
  }

  @MainActor
  private static func playGeolocate(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let maps = LocateMaps()
    let engine = GeolocateControlEngine()
    var reported = 0
    var snapshots: [OrderedJSON] = []
    do {
      for step in steps {
        switch try step.string(at: "step") {
        case "map": engine.configure(map: try step.optionalString(at: "map").map(maps.map))
        case "press": engine.locate(onError: { _ in reported += 1 })
        case "fix":
          try maps.settle(fix: try step.integer(at: "fix"), with: try step.string(at: "answer"))
        case "permission":
          try maps.answer(read: try step.integer(at: "read"), with: try step.string(at: "answer"))
        case let other: throw FixtureError(description: "`\(other)` is no step")
        }
        await GeoControlFixtures.settle {
          [
            engine.state.isBlocked ? 1 : 0, engine.state.isBusy ? 1 : 0,
            engine.state.isLive ? 1 : 0, reported,
          ] + maps.progress
        }
        let state = engine.state
        snapshots.append(
          .object([
            OrderedJSON.Member(key: "blocked", value: .bool(state.isBlocked)),
            OrderedJSON.Member(key: "busy", value: .bool(state.isBusy)),
            OrderedJSON.Member(key: "live", value: .bool(state.isLive)),
            OrderedJSON.Member(key: "reported", value: .number(Double(reported))),
          ]))
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
        OrderedJSON.Member(key: "fixes", value: GeoFixtures.texts(maps.fixes.map(\.map))),
        OrderedJSON.Member(key: "reads", value: GeoFixtures.texts(maps.reads.map(\.map))),
        OrderedJSON.Member(key: "snapshots", value: .array(snapshots)),
      ]))
  }

  // MARK: - The pickers' models, as the fixtures write them

  private static func sectionWritten(_ section: LayersPanelSection) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if section.choice == .overlay {
      members.append(
        OrderedJSON.Member(
          key: "categories",
          value: .array(
            section.categories.map { category in
              .object([
                OrderedJSON.Member(key: "name", value: .string(category.name)),
                OrderedJSON.Member(key: "slug", value: .string(category.slug)),
              ])
            })))
    }
    return .object(
      members + [
        OrderedJSON.Member(key: "category", value: section.category.map { .string($0) } ?? .null),
        OrderedJSON.Member(key: "choice", value: .string(section.choice.rawValue)),
        OrderedJSON.Member(
          key: "heading",
          value: .object([OrderedJSON.Member(key: "word", value: .string(section.heading.word))])),
        OrderedJSON.Member(
          key: "rows",
          value: .array(
            section.rows.map { row in
              .object([
                OrderedJSON.Member(key: "checked", value: .bool(row.isChecked)),
                OrderedJSON.Member(key: "label", value: .string(row.label)),
                OrderedJSON.Member(
                  key: "mark", value: row.mark.map { .string($0.rawValue) } ?? .null),
                OrderedJSON.Member(key: "slug", value: .string(row.slug)),
              ])
            })),
      ])
  }

  private static func preferenceValue(field: String, value: String) throws(FixtureError)
    -> PreferenceValue
  {
    switch PreferenceField(rawValue: field) {
    case .length: .length(RestSchema.UnitLength(rawValue: value))
    case .pace: .pace(RestSchema.UnitPace(rawValue: value))
    case .slope: .slope(RestSchema.UnitSlope(rawValue: value))
    case .temperature: .temperature(RestSchema.UnitTemperature(rawValue: value))
    case .language: .language(RestSchema.Language(rawValue: value))
    case nil: throw FixtureError(description: "`\(field)` is no preference")
    }
  }

  private static func choiceWritten(_ choice: PreferenceChoice) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "field", value: .string(choice.field.rawValue)),
      OrderedJSON.Member(
        key: "options",
        value: .array(
          choice.options.map { option in
            let label: OrderedJSON
            switch option.label {
            case .word(let word):
              label = .object([
                OrderedJSON.Member(key: "word", value: .string("preferences.\(word)"))
              ])
            case .name(let name):
              label = .object([OrderedJSON.Member(key: "name", value: .string(name))])
            }
            return .object([
              OrderedJSON.Member(key: "checked", value: .bool(option.isChecked)),
              OrderedJSON.Member(key: "label", value: label),
              OrderedJSON.Member(key: "value", value: .string(option.value.rawValue)),
            ])
          })),
    ])
  }

  private static func preferencesWritten(_ preferences: UnitPreferences) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "language", value: .string(preferences.language)),
      OrderedJSON.Member(key: "length", value: .string(preferences.length.rawValue)),
      OrderedJSON.Member(key: "pace", value: .string(preferences.pace.rawValue)),
      OrderedJSON.Member(key: "slope", value: .string(preferences.slope.rawValue)),
      OrderedJSON.Member(key: "temperature", value: .string(preferences.temperature.rawValue)),
    ])
  }
}
