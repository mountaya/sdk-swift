import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("layersPanelSections")
struct LayersPanelSectionsTests {
  /// catalogue holds two terrains, the enrichment category of two, the points of interest first, and
  /// two classic categories, named in English and in French but for the satellite and the hazards,
  /// named in English alone.
  private static let catalogue = TileFixtures.layers(
    [
      TileFixtures.category(
        "enrichment",
        children: [
          TileFixtures.named(
            "pois",
            locales: TileFixtures.names(english: "Points of interest", french: "Points d’intérêt")),
          TileFixtures.named(
            "hillshade", locales: TileFixtures.names(english: "Hillshade", french: "Ombrage")),
        ],
        locales: TileFixtures.names(english: "Enrichment", french: "Enrichissement")),
      TileFixtures.category(
        "conditions",
        children: [
          TileFixtures.named(
            "slopes", locales: TileFixtures.names(english: "Slope", french: "Pente")),
          TileFixtures.named(
            "snow-depth",
            locales: TileFixtures.names(english: "Snow depth", french: "Hauteur de neige")),
        ],
        locales: TileFixtures.names(english: "Conditions", french: "Conditions")),
      TileFixtures.category(
        "hazards",
        children: [
          TileFixtures.named("avalanche", locales: TileFixtures.names(english: "Avalanche risk"))
        ],
        locales: TileFixtures.names(english: "Hazards")),
    ],
    terrains: [
      TileFixtures.terrain(
        "topo", locales: TileFixtures.names(english: "Topographic", french: "Topographique")),
      TileFixtures.terrain("satellite", locales: TileFixtures.names(english: "Satellite")),
    ])

  /// marks reads each section's rows as `slug:mark`, `-` for none.
  private static func marks(_ sections: [LayersPanelSection]) -> [[String]] {
    sections.map { section in
      section.rows.map { "\($0.slug):\($0.mark?.rawValue ?? "-")" }
    }
  }

  @Test("the terrains, the enrichments but the points of interest, then the overlays' category")
  func order() {
    let sections = layersPanelSections(
      LayersSelection(
        catalogue: Self.catalogue, terrain: "satellite", overlay: "slopes",
        enrichments: ["pois", "hillshade"]),
      language: "en", isLocked: { $0 == "snow-depth" })

    #expect(
      sections.map(\.heading.word) == ["layers.terrain", "layers.enrichment", "layers.overlays"])
    #expect(sections.map(\.choice) == [.terrain, .enrichment, .overlay])
    #expect(sections.map(\.category) == [nil, "enrichment", "conditions"])
    #expect(
      Self.marks(sections) == [
        ["topo:-", "satellite:tick"], ["hillshade:tick"], ["slopes:tick", "snow-depth:lock"],
      ])
    #expect(sections[0].rows.map(\.label) == ["Topographic", "Satellite"])
    #expect(
      sections[2].categories == [
        LayersPanelCategory(slug: "conditions", name: "Conditions"),
        LayersPanelCategory(slug: "hazards", name: "Hazards"),
      ])
    #expect(sections[0].categories.isEmpty && sections[1].categories.isEmpty)
    #expect(poisOverlaySlug == "pois")
  }

  @Test("the overlays open on the reader's pick, else the selected overlay's, else the first")
  func openCategory() {
    func opened(picked: String?, overlay: String?) -> String? {
      layersPanelSections(
        LayersSelection(catalogue: Self.catalogue, overlay: overlay), language: "en",
        picked: picked
      ).first { $0.choice == .overlay }?.category
    }

    #expect(opened(picked: "hazards", overlay: "slopes") == "hazards")
    #expect(opened(picked: nil, overlay: "avalanche") == "hazards")
    #expect(opened(picked: nil, overlay: nil) == "conditions")
    #expect(opened(picked: "weather", overlay: "avalanche") == "hazards", "no category on offer")
    #expect(opened(picked: "enrichment", overlay: "avalanche") == "hazards", "no classic pick")
    #expect(opened(picked: nil, overlay: "radar") == "conditions")
    #expect(
      layersPanelSections(
        LayersSelection(catalogue: Self.catalogue), language: "en", picked: "hazards"
      ).last?.rows.map(\.slug) == ["avalanche"], "its rows are the open category's")
  }

  @Test("a category holding no overlay is not offered, and none offered lists no overlays")
  func offered() {
    var catalogue = Self.catalogue
    catalogue.overlays[1].children = []
    let sections = layersPanelSections(LayersSelection(catalogue: catalogue), language: "en")
    #expect(sections.last?.categories.map(\.slug) == ["hazards"])
    #expect(sections.last?.category == "hazards")

    catalogue.overlays.removeLast(2)
    #expect(
      layersPanelSections(LayersSelection(catalogue: catalogue), language: "en").map(\.choice)
        == [.terrain, .enrichment])
  }

  @Test("an enrichment category of the points of interest alone lists no switch")
  func poisAlone() {
    var catalogue = Self.catalogue
    catalogue.overlays[0].children.removeLast()
    let sections = layersPanelSections(
      LayersSelection(catalogue: catalogue, enrichments: ["pois"]), language: "en")

    #expect(sections.map(\.choice) == [.terrain, .overlay])
  }

  @Test("the time stands last where the host offers it, the catalogue read or not")
  func time() {
    let offered = layersPanelSections(
      LayersSelection(catalogue: Self.catalogue), language: "en", offersTime: true)
    #expect(offered.map(\.choice) == [.terrain, .enrichment, .overlay, .time])
    #expect(
      offered.last
        == LayersPanelSection(
          heading: LayersPanelHeading(word: "layers.time"), choice: .time, category: nil, rows: []))
    #expect(
      layersPanelSections(LayersSelection(), language: "en", offersTime: true).map(\.choice)
        == [.terrain, .time])
  }

  @Test("an entry and a category are named in the reader's language, else in English, else by slug")
  func names() {
    var catalogue = Self.catalogue
    catalogue.overlays[1].children.append(TileFixtures.overlay("aspect"))
    let sections = layersPanelSections(
      LayersSelection(catalogue: catalogue, terrain: "topo"), language: "fr-CA")

    #expect(sections[0].rows.map(\.label) == ["Topographique", "Satellite"])
    #expect(sections[1].rows.map(\.label) == ["Ombrage"])
    #expect(sections[2].rows.map(\.label) == ["Pente", "Hauteur de neige", "aspect"])
    #expect(sections[2].categories.map(\.name) == ["Conditions", "Hazards"])
  }

  @Test("a locked entry shows its lock in place of its tick")
  func locked() {
    let sections = layersPanelSections(
      LayersSelection(catalogue: Self.catalogue, terrain: "satellite", enrichments: ["hillshade"]),
      language: "en", isLocked: { ["satellite", "hillshade"].contains($0) })

    #expect(
      Self.marks(sections) == [
        ["topo:-", "satellite:lock"], ["hillshade:lock"], ["slopes:-", "snow-depth:-"],
      ])
    #expect(sections[0].rows[1].isChecked)
  }

  @Test("the terrains' section stands with no card while the catalogue is still to land")
  func noCatalogue() {
    let sections = layersPanelSections(LayersSelection(terrain: "topo"), language: "en")

    #expect(
      sections == [
        LayersPanelSection(
          heading: LayersPanelHeading(word: "layers.terrain"), choice: .terrain, category: nil,
          rows: [])
      ])
  }

  @Test("the selection holds an entry, and a pick a category, by its scalars")
  func scalars() {
    let catalogue = TileFixtures.layers([
      TileFixtures.category("conditions", children: [TileFixtures.overlay("caf\u{E9}")]),
      TileFixtures.category("m\u{E9}t\u{E9}o", children: [TileFixtures.overlay("wind")]),
    ])
    let sections = layersPanelSections(
      LayersSelection(catalogue: catalogue, overlay: "cafe\u{301}"), language: "en",
      picked: "me\u{301}te\u{301}o")

    #expect(sections[1].category == "conditions")
    #expect(sections[1].rows.map(\.isChecked) == [false])
  }
}
