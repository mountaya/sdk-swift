/// poiPanelRows is what a points-of-interest picker offers over the keys `drawn` at the
/// points-of-interest rank, in the order drawn (`geo.layers.poi-rows`).
///
/// A row is offered for what is drawn alone: a curated key whose concept is not drawn would be a
/// toggle that changes nothing. With no curation, a row stands per drawn key; `keys` curates them,
/// a row per key it lists that is drawn, in its own order; and `groups`, which supersede `keys`, a
/// row per group with a key drawn, driving its drawn keys alone, so a concept survives a layer
/// behind it the catalogue lacks. A row is on while any key it drives is shown, as `isKeyVisible`
/// answers it, or, where the app holds the groups' state itself in `activeGroups`, while it holds
/// the group on. A key's row is labelled from `labels`, else by the key itself. The master row
/// reads the rows, never a word of its own, so it is on while any row is and can never say the
/// overlay is off with a row under it on. Keys and ids are compared by their scalars.
public func poiPanelRows(
  drawn: [String], isKeyVisible: (String) -> Bool, keys: [String]? = nil,
  groups: [POIPanelGroup]? = nil, activeGroups: [String]? = nil, labels: [String: String] = [:]
) -> POIPanelRows {
  func isDrawn(_ key: String) -> Bool { drawn.contains { sameText($0, key) } }
  let rows: [POIPanelRow]
  if let groups {
    rows = groups.compactMap { group in
      let driven = group.keys.filter(isDrawn)
      guard !driven.isEmpty else { return nil }
      let isVisible =
        activeGroups.map { held in held.contains { sameText($0, group.id) } }
        ?? driven.contains(where: isKeyVisible)
      return POIPanelRow(
        id: group.id, label: group.label, glyph: group.glyph, keys: driven, isVisible: isVisible)
    }
  } else {
    rows = (keys?.filter(isDrawn) ?? drawn).map { key in
      POIPanelRow(id: key, label: labels[key] ?? key, keys: [key], isVisible: isKeyVisible(key))
    }
  }
  return POIPanelRows(rows: rows, isAnyVisible: rows.contains(where: \.isVisible))
}

/// poiPanelNoteZoom is the zoom below which a points-of-interest picker notes that the overlay
/// draws nothing (`geo.layers.poi-rows`): the overlay's floor zoom, `minZoom`, and no zoom at all,
/// negative infinity, where it states none or one that is no number, so the note is never raised
/// there. The note stands while the camera's zoom is not at least this zoom: below the floor, never
/// at it.
public func poiPanelNoteZoom(_ minZoom: Double?) -> Double {
  guard let minZoom, !minZoom.isNaN else { return -.infinity }
  return minZoom
}
