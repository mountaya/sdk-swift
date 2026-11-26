import MountayaClient

/// poisOverlaySlug is the slug of the points-of-interest overlay, an enrichment its own picker
/// drives (`geo.layers.poi-rows`), which a layers picker never lists (`geo.layers.picker-rows`).
public let poisOverlaySlug = "pois"

/// layersPanelSections is what a layers picker lists over `selection` (`geo.layers.picker-rows`), in
/// the sections and the order of the map studio's layers panel:
///
/// - **the terrains**, headed by `layers.terrain`, as picture cards in one choice, the section
///   standing while the catalogue is still to land, with no card;
/// - **the enrichments**, headed by `layers.enrichment`, as switches, the overlays of every
///   enrichment category in the catalogue's order but the points of interest, `poisOverlaySlug`,
///   which their own picker drives, the section standing only where it lists a row;
/// - **the classic overlays**, headed by `layers.overlays`, as picture cards in one choice across
///   every classic category, shown one category at a time: `categories` lists each classic category
///   holding an overlay, a switch drawn between them where it lists two or more, and the section
///   opens on `picked`, the category the reader picked last in that switch, where it names a listed
///   one, else on the first listed category holding the selected overlay, else on the first, its
///   rows that category's overlays; it stands only where it lists a category;
/// - **the time**, headed by `layers.time`, with no row, where the host offers it, `offersTime`.
///
/// The split between the enrichments and the classic overlays is the catalogue's, never a
/// preference: base maps replace one another, classic overlays replace one another across
/// categories, since two of them repaint the same ground, and enrichments stack
/// (`overlayKindOf(_:)`). A row is named in `language`, else in English, else by its slug
/// (`localizedName(locales:slug:language:)`), and so is a category. A row is checked where the
/// selection holds its slug, compared by scalars, and shows its lock where `isLocked` says the entry
/// is out of the viewer's reach, in place of any tick, else a tick where it is checked.
public func layersPanelSections(
  _ selection: LayersSelection, language: String, isLocked: (String) -> Bool = { _ in false },
  picked: String? = nil, offersTime: Bool = false
) -> [LayersPanelSection] {
  func row(_ slug: String, locales: TileSchema.Locales, isChecked: Bool) -> LayersPanelRow {
    LayersPanelRow(
      slug: slug, label: localizedName(locales: locales, slug: slug, language: language),
      isChecked: isChecked, mark: isLocked(slug) ? .lock : isChecked ? .tick : nil)
  }
  let catalogue = selection.catalogue
  var sections = [
    LayersPanelSection(
      heading: LayersPanelHeading(word: "layers.terrain"), choice: .terrain, category: nil,
      rows: (catalogue?.terrains ?? []).map { terrain in
        row(
          terrain.slug, locales: terrain.locales,
          isChecked: sameText(terrain.slug, selection.terrain))
      })
  ]
  let categories = catalogue?.overlays ?? []
  let enrichments = categories.filter { overlayKindOf($0) == .enrichment }.flatMap(\.children)
    .filter { !sameText($0.slug, poisOverlaySlug) }
  if !enrichments.isEmpty {
    sections.append(
      LayersPanelSection(
        heading: LayersPanelHeading(word: "layers.enrichment"), choice: .enrichment,
        category: enrichmentCategorySlug,
        rows: enrichments.map { child in
          row(
            child.slug, locales: child.locales,
            isChecked: selection.enrichments.contains { sameText($0, child.slug) })
        }))
  }
  let classic = categories.filter { overlayKindOf($0) == .classic && !$0.children.isEmpty }
  if let first = classic.first {
    var offered: [LayersPanelCategory] = []
    for category in classic {
      offered.append(
        LayersPanelCategory(
          slug: category.slug,
          name: localizedName(locales: category.locales, slug: category.slug, language: language)))
    }
    let open =
      classic.first { sameText($0.slug, picked) }
      ?? classic.first { $0.children.contains { sameText($0.slug, selection.overlay) } } ?? first
    sections.append(
      LayersPanelSection(
        heading: LayersPanelHeading(word: "layers.overlays"), choice: .overlay,
        category: open.slug,
        rows: open.children.map { child in
          row(
            child.slug, locales: child.locales, isChecked: sameText(child.slug, selection.overlay))
        },
        categories: offered))
  }
  if offersTime {
    sections.append(
      LayersPanelSection(
        heading: LayersPanelHeading(word: "layers.time"), choice: .time, category: nil, rows: []))
  }
  return sections
}
