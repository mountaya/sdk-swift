import GateSupport
import Testing

@Suite("Registry")
struct RegistryTests {
  private static let sample = """
    # A comment before anything.

    version: 6

    capabilities:
      # ── transport ──
      - id: transport.base-urls
        layer: transport
        api: true
        rule: >-
          Each public surface has its own default origin, and a client overrides them
          independently.
        fixture: transport/base-urls.json
        published:
          typescript:
            - BaseUrlOverrides
            # A comment inside a list.
            - defaultBaseURLs

          dart:
            - BaseURLs
          swift:
            - BaseURLs
            - MapEngine.features(at:)
            - APIError.Kind.preconditionFailed
            - GlyphSet.init(chaining:)
            - MapEngine.close()
            - isAPIError(_:)
          kotlin: scoped

      - id: map.engine.patch
        layer: map
        api: false
        rule: >-
          One sentence.
        fixture: map/engine-patch.json

      - id: studio.capabilities
        layer: studio
        api: false
        rule: >-
          One sentence.
        fixture: studio/capabilities.json
    """

  @Test("it reads the version and every entry")
  func readsEntries() throws {
    let registry = try Registry.parse(Self.sample)

    #expect(registry.version == 6)
    #expect(
      registry.capabilities.map(\.id)
        == ["transport.base-urls", "map.engine.patch", "studio.capabilities"]
    )
    let first = try #require(registry.capabilities.first)
    #expect(first.layer == .transport)
    #expect(first.api)
    #expect(first.fixture == "transport/base-urls.json")
    #expect(
      first.rule
        == "Each public surface has its own default origin, and a client overrides them independently."
    )
    #expect(first.line == 7)
    #expect(
      first.published
        == Registry.Published(
          typescript: .names(["BaseUrlOverrides", "defaultBaseURLs"]),
          dart: .names(["BaseURLs"]),
          swift: .names([
            "BaseURLs", "MapEngine.features(at:)", "APIError.Kind.preconditionFailed",
            "GlyphSet.init(chaining:)", "MapEngine.close()", "isAPIError(_:)",
          ]),
          kotlin: .scoped))
    #expect(registry.capabilities.map(\.layer) == [.transport, .map, .studio])
    #expect(registry.capabilities.dropFirst().map(\.published) == [nil, nil])
    #expect(registry.capabilities.last?.api == false)
  }

  /// entry is a complete entry whose `published` field is `published`, its lines indented as an
  /// entry's field is.
  private static func entry(published: String) -> String {
    "version: 6\ncapabilities:\n  - id: a.b\n    layer: geo\n    api: true\n    rule: >-\n"
      + "      R.\n    fixture: geo/a.json\n" + published
  }

  @Test(
    "`published` is the four columns, each once, each `scoped` or a list of one name or more",
    arguments: [
      ("    published:\n", 9),
      ("    published:\n    published:\n      swift: scoped\n", 10),
      ("    published: [A, B]\n", 9),
      ("    published:\n      A\n", 10),
      ("    published:\n        - A\n", 10),
      (
        "    published:\n      typescript:\n        - A\n      dart:\n        - A\n      swift:\n"
          + "        - A\n", 9
      ),
      (
        "    published:\n      typescript: scoped\n      dart: scoped\n      swift: scoped\n"
          + "      kotlin: scoped\n      java: scoped\n", 14
      ),
      ("    published:\n      swift: scoped\n      swift: scoped\n", 11),
      ("    published:\n      swift: [A]\n", 10),
      ("    published:\n      swift: Scoped\n", 10),
      ("    published:\n      swift:scoped\n", 10),
      (
        "    published:\n      typescript: scoped\n      dart: scoped\n      swift:\n"
          + "      kotlin: scoped\n", 12
      ),
      ("    published:\n      swift: scoped\n        - A\n", 11),
      ("    published:\n      swift:\n          - A\n", 11),
      ("    published:\n       swift: scoped\n", 10),
      ("    published:\n      swift:\n        A\n", 11),
      ("    published:\n      swift: scoped\n      - A\n", 11),
      ("    published:\n      - A\n      swift: scoped\n", 10),
      ("    published:\n      kotlin:\n        - \"A\"\n", 11),
      ("    published:\n      kotlin:\n        - A B\n", 11),
      ("    published:\n      kotlin:\n        - A\n        - A\n", 12),
    ]
  )
  func publishedRefusals(published: String, line: Int) {
    do {
      _ = try Registry.parse(Self.entry(published: published))
      Issue.record("the registry parsed")
    } catch {
      #expect(error.line == line, "\(error)")
    }
  }

  @Test(
    "a name of the `swift` column is a path of an API baseline, listed once",
    arguments: [
      ("        - MapEngine.features(at)\n", 11),
      ("        - MapEngine.features(at:)x\n", 11),
      ("        - features(at::)\n", 11),
      ("        - features(at:(b:))\n", 11),
      ("        - MapEngine.==(_:_:)\n", 11),
      ("        - has_underscore\n", 11),
      ("        - 1Leading\n", 11),
      ("        - Type.\n", 11),
      ("        - .member\n", 11),
      ("        - Type..member\n", 11),
      ("        - BaseURLs\n        - BaseURLs\n", 12),
    ]
  )
  func swiftRefusals(names: String, line: Int) {
    do {
      _ = try Registry.parse(Self.entry(published: "    published:\n      swift:\n" + names))
      Issue.record("the registry parsed")
    } catch {
      #expect(error.line == line, "\(error)")
    }
  }

  @Test("the `swift` column takes Swift's own spellings, a case apart being another name")
  func swiftSpellings() throws {
    let names = [
      "POIStyle", "PoiStyle", "APIError.IdempotentAnswer", "haversineMeters(from:to:)",
      "MapEngine.fitBounds(_:with:)", "ScriptedMapSurface.init(drawing:)", "MapEngine.events()",
    ]
    let registry = try Registry.parse(
      Self.entry(
        published: "    published:\n      typescript: scoped\n      dart: scoped\n      swift:\n"
          + names.map { "        - \($0)\n" }.joined() + "      kotlin: scoped\n"))

    #expect(registry.capabilities.first?.published?.swift == .names(names))
  }

  @Test("a field after the columns ends them, and the next entry starts afresh")
  func publishedThenField() throws {
    let registry = try Registry.parse(
      "version: 6\ncapabilities:\n  - id: a.b\n    layer: geo\n    published:\n"
        + "      typescript: scoped\n      dart: scoped\n      swift:\n        - A\n"
        + "      kotlin: scoped\n"
        + "    api: true\n    rule: >-\n      R.\n    fixture: geo/a.json\n"
        + "  - id: a.c\n    layer: geo\n    api: false\n    rule: >-\n      R.\n"
        + "    fixture: geo/c.json\n"
    )

    let first = Registry.Published(
      typescript: .scoped, dart: .scoped, swift: .names(["A"]), kotlin: .scoped)
    #expect(registry.capabilities.map(\.published) == [first, nil])
  }

  @Test(
    "anything it does not recognise is an error naming the line",
    arguments: [
      (
        "version: 6\ncapabilities:\n  - id: a.b\n    layer: geo\n    api: true\n    owner: someone\n",
        6
      ),
      ("version: 6\ncapabilities:\n  - id: a.b\n    layer: elements\n", 4),
      ("version: 6\ncapabilities:\n  - id: a.b\n    api: yes\n", 4),
      ("version: one\n", 1),
      ("version: 6\nextra: true\n", 2),
      ("version: 6\ncapabilities:\n  - id: A.B\n", 3),
      (
        "version: 6\ncapabilities:\n  - id: a.b\n    layer: geo\n    api: true\n    rule: one line\n",
        6
      ),
      ("version: 6\ncapabilities:\n  - id: a.b\n    layer: geo\n      nested: 1\n", 5),
      ("version: 6\ncapabilities:\n  - id: a.b\n    fixture: ../outside.json\n", 4),
      ("version: 6\ncapabilities:\n  - name: a.b\n", 3),
    ]
  )
  func refusals(text: String, line: Int) {
    do {
      _ = try Registry.parse(text)
      Issue.record("the registry parsed")
    } catch {
      #expect(error.line == line, "\(error)")
    }
  }

  @Test("an entry missing a field, and an id declared twice, are errors on the entry's line")
  func incompleteAndDuplicate() {
    let entry = "  - id: a.b\n    layer: geo\n    api: true\n    rule: >-\n      R.\n"
    #expect(throws: RegistryError.self) {
      try Registry.parse("version: 6\ncapabilities:\n" + entry)
    }
    let complete = entry + "    fixture: geo/a.json\n"
    do {
      _ = try Registry.parse("version: 6\ncapabilities:\n" + complete + complete)
      Issue.record("the registry parsed")
    } catch {
      #expect(error.line == 9)
    }
    #expect(throws: RegistryError.self) { try Registry.parse("capabilities:\n" + complete) }
  }
}
