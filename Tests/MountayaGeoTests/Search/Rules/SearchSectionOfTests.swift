import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("searchSectionOf")
struct SearchSectionOfTests {
  @Test("each branch fills its section from its own member of the answer, in the answer's order")
  func branches() {
    let english = SearchWording()
    for (branch, kind) in [
      (DataSchema.SearchTarget.places, "place"), (.pois, "poi"), (.ways, "way"),
      (.itineraries, "itinerary"), (.collections, "collection"), (.zones, "zone"),
    ] {
      let section = searchSectionOf(
        HeldSearch.result(branch, names: ["Mont Blanc", "Mont Joly"]), branch: branch,
        folded: foldedQuery("mont"), wording: english)
      #expect(section.id == branch)
      #expect(section.state.isSettled)
      #expect(section.rows.map(\.title) == ["Mont Blanc", "Mont Joly"], "\(kind)")
      #expect(section.rows.allSatisfy { $0.id.hasPrefix("\(kind):") })
      #expect(section.rows.first.map { $0.matched.count == 1 } == true, "the query emphasized")
    }
  }

  /// A round folds its query once, and every row of every section is matched against that fold:
  /// the rows are the ones each row rule answers for the query itself.
  @Test("every row matched against the round's one fold is the row its rule builds for the query")
  func foldedOnce() {
    let wording = SearchWording()
    let names = [
      "Mont Blanc", "\u{C9}vian-les-Bains", "Stra\u{DF}e du Mont", "\u{141}\u{F3}d\u{17A}",
    ]
    for query in ["mont", "evian", "strasse", "lodz", "", "\u{301}"] {
      let folded = foldedQuery(query)
      func section(_ branch: DataSchema.SearchTarget) -> [SearchRow] {
        searchSectionOf(
          HeldSearch.result(branch, names: names), branch: branch, folded: folded, wording: wording
        ).rows
      }
      let answers = { (branch: DataSchema.SearchTarget) in HeldSearch.result(branch, names: names) }
      #expect(
        section(.places)
          == (answers(.places).places?.places ?? []).compactMap {
            placeRow($0, query: query, wording: wording)
          }, "\(query)")
      #expect(
        section(.pois)
          == (answers(.pois).pois?.pois ?? []).compactMap {
            poiRow($0, query: query, wording: wording)
          }, "\(query)")
      #expect(
        section(.ways)
          == (answers(.ways).ways?.ways ?? []).compactMap {
            wayRow($0, query: query, wording: wording)
          }, "\(query)")
      #expect(
        section(.itineraries)
          == (answers(.itineraries).itineraries?.itineraries ?? []).compactMap {
            itineraryRow($0, query: query)
          }, "\(query)")
      #expect(
        section(.collections)
          == (answers(.collections).collections?.collections ?? []).compactMap {
            collectionRow($0, query: query)
          }, "\(query)")
      #expect(
        section(.zones)
          == (answers(.zones).zones?.zones ?? []).compactMap { zoneRow($0, query: query) },
        "\(query)")
    }
  }

  @Test("a branch reads its own member alone, and none where the answer holds none")
  func ownMember() {
    let places = HeldSearch.result(.places, names: ["Chamonix"])
    #expect(
      searchSectionOf(places, branch: .zones, folded: [], wording: SearchWording()).rows.isEmpty)
    #expect(
      searchSectionOf(
        DataSchema.SearchResult(), branch: .places, folded: [], wording: SearchWording()
      )
      .state.isSettled)
    let unknown = searchSectionOf(
      places, branch: DataSchema.SearchTarget(rawValue: "TRAILS"), folded: [],
      wording: SearchWording())
    #expect(unknown.rows.isEmpty && unknown.state.isSettled)
  }

  @Test("an error the answer reports for the branch wins over what came with it")
  func reported() throws {
    var answer = HeldSearch.result(.pois, names: ["Refuge"])
    answer.errors = [
      DataSchema.SearchTargetError {
        $0.target = .zones
        $0.message = "zones failed"
      },
      DataSchema.SearchTargetError {
        $0.target = .pois
        $0.code = .badGateway
        $0.message = "pois failed"
      },
    ]
    let section = searchSectionOf(answer, branch: .pois, folded: [], wording: SearchWording())
    #expect(section.rows.isEmpty)
    let failure = try #require(section.state.failure as? SearchBranchError)
    #expect(failure == SearchBranchError(target: .pois, code: .badGateway, message: "pois failed"))
    #expect(
      searchSectionOf(answer, branch: .places, folded: [], wording: SearchWording()).state
        .isSettled,
      "another branch's report is not this one's")
  }

  @Test("a result that renders as no row is left out, and a row worded for the reader")
  func rows() {
    let answer = DataSchema.SearchResult {
      $0.places = DataSchema.GeocodeResult {
        $0.places = [
          SearchEntities.place(name: "Annecy"), SearchEntities.place(name: "Nowhere", point: nil),
        ]
      }
    }
    let section = searchSectionOf(
      answer, branch: .places, folded: [],
      wording: SearchWording(resolveLabel: { _ in "Localit\u{E9}" }))
    #expect(section.rows.map(\.title) == ["Annecy"])
    #expect(section.rows.first?.secondary == .text("Localit\u{E9}"))
  }
}
