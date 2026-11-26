import MountayaClient

/// watermarkDrawing is the drawing of the glyph table the watermark is drawn from.
package let watermarkDrawing = "watermark"

/// watermarkLabelWord is the path of the word the watermark is labelled by.
package let watermarkLabelWord = "watermark.label"

/// watermarkRoot is Mountaya's site, which the mark links to in every language that has no page
/// of its own there.
package let watermarkRoot = "https://www.mountaya.com/"

/// watermarkLinks is the page of Mountaya's site in each language that has one.
package let watermarkLinks: [RestSchema.Language: String] = [
  .en: "https://www.mountaya.com/en/",
  .fr: "https://www.mountaya.com/fr/",
]

/// watermarkFirstPartyOrigins is Mountaya's own origins, on which a browser's top-level page omits
/// the mark, since a visitor there is already on Mountaya.
package let watermarkFirstPartyOrigins = [
  "https://app.mountaya.com", "https://mountaya.com", "https://www.mountaya.com",
]

/// watermarkOf answers the Mountaya watermark a map draws, or nil where it draws none
/// (`geo.organization.watermark`): none while the read of its organization waits within one
/// attempt's time budget or once it answers white label, and the mark once it answers none, once
/// it failed, once one attempt's budget has passed with no answer, its further attempts going on
/// or not, and at once for a client holding no publishable key, which makes no read. Nothing a
/// host states takes it off, and there is no parameter here that could.
///
/// `page` is the browser document a map is drawn in, its origin and whether it is a top-level
/// page, which a browser alone has: a top-level page on one of `watermarkFirstPartyOrigins`,
/// compared whole, omits the mark, and a framed one keeps it on every origin. A map this SDK draws
/// is in no browser document, so `MapView` hands none, and once its read has answered, white label
/// alone keeps its mark off; the clause stands here so the rule answers every case the contract
/// states.
///
/// The mark is the glyph table's `watermark` drawing, `watermark-width` wide and as tall as its
/// box's proportion makes it, its top-left corner `watermark-inset` on both axes from the top-left
/// corner of the map's safe area, the part of the map the device leaves visible, so the empty
/// margin the drawing keeps round the mark falls outside it. It links to Mountaya's
/// site in `language`, the language the elements' words are in, English and French having a page
/// each and every other language the site's root, and is labelled by `watermark.label`.
package func watermarkOf(
  _ read: OrganizationRead, language: RestSchema.Language,
  page: (origin: String, topLevel: Bool)? = nil
) -> MapWatermark? {
  if let page, page.topLevel,
    watermarkFirstPartyOrigins.contains(where: { sameText($0, page.origin) })
  {
    return nil
  }
  switch read {
  case .waiting, .answered(whiteLabel: true): return nil
  case .answered(whiteLabel: false), .timedOut, .failed, .noKey: break
  }
  let href =
    watermarkLinks.first { sameText($0.key, language) }?.value ?? watermarkRoot
  return MapWatermark(
    drawing: watermarkDrawing, x: watermarkInset, y: watermarkInset, width: watermarkWidth,
    height: watermarkHeight, href: href, label: watermarkLabelWord)
}
