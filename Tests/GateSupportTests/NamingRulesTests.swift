import GateSupport
import Testing

@Suite("NamingRules")
struct NamingRulesTests {
  private typealias Symbol = SymbolGraph.Symbol

  /// machine declares a type where the layout law files a machine.
  static func machine(_ name: String) -> SymbolGraph.Symbol {
    SymbolGraph.Symbol(
      kind: "swift.class",
      path: [name],
      file: "/repo/Sources/MountayaGeo/Search/Engines/\(name).swift"
    )
  }

  private func rules(_ symbols: [Symbol], exemptions: [String: String] = [:]) -> [String] {
    NamingRules.check(symbols: symbols, exemptions: exemptions).findings.map {
      "\($0.name): \($0.rule)"
    }
  }

  @Test("names the law allows pass")
  func allowedNames() {
    let report = NamingRules.check(
      symbols: [
        Symbol(kind: "swift.struct", path: ["Mountaya"]),
        Symbol(kind: "swift.actor", path: ["SessionTokenEngine"]),
        Symbol(kind: "swift.struct", path: ["InertLocationSource"]),
        Symbol(kind: "swift.struct", path: ["URLSessionSeam"], accessLevel: "internal"),
        Symbol(kind: "swift.property", path: ["MapView", "onTap"]),
        Symbol(kind: "swift.property", path: ["SearchField", "onQueryChange"]),
        Symbol(kind: "swift.method", path: ["Panel", "onTogglePanel(_:)"], parameterLabels: ["_"]),
        Symbol(
          kind: "swift.method", path: ["Loader", "loadHttpUrl(from:)"], parameterLabels: ["from"]),
        Symbol(
          kind: "swift.init", path: ["Origins", "init(rest:tiles:)"],
          parameterLabels: ["rest", "tiles"]),
        Symbol(kind: "swift.property", path: ["Clock", "now"], accessLevel: "internal"),
        Symbol(kind: "swift.struct", path: ["RestSchema", "Collection"]),
        Symbol(kind: "swift.struct", path: ["BaseURLs"]),
        Symbol(kind: "swift.enum", path: ["QueriedFeature", "ID"]),
      ],
      exemptions: [:]
    )

    #expect(report.findings.isEmpty, "\(report.findings)")
    #expect(report.passes)
    #expect(report.summary == "13 checked, 0 exempt")
  }

  @Test(
    "a planted violation fails",
    arguments: [
      (Symbol(kind: "swift.struct", path: ["MountayaNavigationView"]), "prefix"),
      (NamingRulesTests.machine("NavigationController"), "engine"),
      (NamingRulesTests.machine("LocationManager"), "engine"),
      (NamingRulesTests.machine("TileService"), "engine"),
      (NamingRulesTests.machine("RouteCoordinator"), "engine"),
      (NamingRulesTests.machine("SearchSession"), "engine"),
      (Symbol(kind: "swift.enum", path: ["GeometryHelper"], accessLevel: "internal"), "vague"),
      (Symbol(kind: "swift.enum", path: ["StringUtils"], accessLevel: "internal"), "vague"),
      (Symbol(kind: "swift.struct", path: ["NoopLocationSource"]), "inert"),
      (Symbol(kind: "swift.struct", path: ["NullLocationSource"]), "inert"),
      (Symbol(kind: "swift.struct", path: ["NoOpLocationSource"]), "inert"),
      (Symbol(kind: "swift.struct", path: ["NeverSleeper"], accessLevel: "internal"), "inert"),
      (Symbol(kind: "swift.struct", path: ["SilentNotifier"]), "inert"),
      (Symbol(kind: "swift.var", path: ["noopLocationSource"]), "inert"),
      (Symbol(kind: "swift.struct", path: ["LocationSourceInert"]), "inert"),
      (Symbol(kind: "swift.property", path: ["MapView", "onClick"]), "handler"),
      (Symbol(kind: "swift.property", path: ["MapView", "onDismiss"]), "handler"),
      (Symbol(kind: "swift.property", path: ["MapView", "onFinish"]), "handler"),
      (Symbol(kind: "swift.method", path: ["Loader", "loadHTTPURL()"]), "acronym"),
      (Symbol(kind: "swift.struct", path: ["ApiError"]), "acronym"),
      (Symbol(kind: "swift.struct", path: ["BaseUrls"]), "acronym"),
      (Symbol(kind: "swift.enum", path: ["QueriedFeature", "Id"]), "acronym"),
      (
        Symbol(kind: "swift.property", path: ["Session", "userID"], accessLevel: "internal"),
        "acronym"
      ),
      (
        Symbol(kind: "swift.init", path: ["View", "init(onPress:)"], parameterLabels: ["onPress"]),
        "handler"
      ),
      (Symbol(kind: "swift.struct", path: ["Error"]), "shadow"),
      (Symbol(kind: "swift.struct", path: ["Collection"]), "shadow"),
    ]
  )
  func plantedViolations(symbol: SymbolGraph.Symbol, rule: String) {
    let findings = NamingRules.check(symbols: [symbol], exemptions: [:]).findings

    #expect(findings.contains { $0.rule == rule }, "\(symbol.qualifiedName): \(findings)")
  }

  @Test("outside `Engines` the five words are the domain's")
  func engineWordsOutsideEngines() {
    // `sdk/SPEC.md` §9: a machine is what the layout files under `Engines`, and plain data
    // about an edit in progress may be an edit session.
    let value = Symbol(
      kind: "swift.struct",
      path: ["SegmentEditSession"],
      file: "/repo/Sources/MountayaGeo/Segments/Contracts/SegmentEditSession.swift"
    )
    #expect(rules([value]).isEmpty)
  }

  @Test("a refused word is read whole, never as a prefix")
  func nullObjectWordsAreWhole() {
    #expect(rules([Symbol(kind: "swift.struct", path: ["NullableValue"])]).isEmpty)
    #expect(rules([Symbol(kind: "swift.struct", path: ["Nothing"])]).isEmpty)
    #expect(
      rules([Symbol(kind: "swift.func", path: ["normalize(_:)"], parameterLabels: ["_"])]).isEmpty)
  }

  @Test("a handler is read where a consumer is handed one")
  func handlersArePublished() {
    let internalHandler = Symbol(
      kind: "swift.property", path: ["Transport", "onFinish"], accessLevel: "internal")
    #expect(rules([internalHandler]).isEmpty)
  }

  @Test("the law stops at the generated boundary")
  func generatedIsNotRead() {
    let generated = Symbol(
      kind: "swift.struct",
      path: ["MountayaThing"],
      file: "/repo/Sources/MountayaClient/Generated/Rest/MountayaThing.swift"
    )
    let report = NamingRules.check(symbols: [generated], exemptions: [:])

    #expect(report.findings.isEmpty)
    #expect(report.checked == 0)
  }

  @Test("a shadowed name is refused only where a consumer can see it at the top level")
  func shadowIsForPublishedTopLevelTypes() {
    #expect(rules([Symbol(kind: "swift.struct", path: ["Data"], accessLevel: "internal")]).isEmpty)
    #expect(rules([Symbol(kind: "swift.struct", path: ["Mountaya", "Data"])]).isEmpty)
    #expect(rules([Symbol(kind: "swift.struct", path: ["Data"])]) == ["Data: shadow"])
  }

  @Test("an exemption covers its name, is counted, and fails when it names nothing")
  func exemptions() {
    let symbols = [
      Symbol(kind: "swift.enum", path: ["MountayaError"]),
      Symbol(kind: "swift.struct", path: ["Mountaya"]),
    ]
    let sentence = "A bare Error would shadow the standard library's protocol."
    let covered = NamingRules.check(symbols: symbols, exemptions: ["MountayaError": sentence])

    #expect(covered.passes)
    #expect(covered.exempt == ["MountayaError"])
    #expect(covered.summary == "2 checked, 1 exempt")

    let stale = NamingRules.check(
      symbols: symbols,
      exemptions: [
        "MountayaError": sentence, "MountayaAbsent": "A sentence about a name no file declares.",
      ]
    )
    #expect(!stale.passes)
    #expect(stale.staleExemptions == ["MountayaAbsent"])
  }
}
