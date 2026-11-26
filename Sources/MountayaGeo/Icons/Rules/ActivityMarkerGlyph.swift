import MountayaClient

/// activityMarkerPrefix is the namespace an activity's silhouette opens with in an icon set, so an
/// activity's slug never names a waypoint's icon and one marker is never drawn as another.
public let activityMarkerPrefix = "activity-"

/// activityMarkerGlyph is the name of the glyph that draws `activity`'s silhouette inside a marker
/// in `set`, `activity-` then its slug, `hiking-and-trail` as `activity-hiking-and-trail`, or nil
/// where the set holds no such glyph or the slug is empty (`geo.icons.resolution`).
///
/// An activity is looked up under its prefix alone, so a glyph the set holds under the bare slug
/// is no activity's. Nil rather than a fallback: the caller knows what its own marker means and
/// chooses a pin, and an activity whose artwork a set does not carry takes the same path.
public func activityMarkerGlyph(_ activity: RestSchema.ActivitySlug, in set: GlyphSet) -> String? {
  guard !activity.rawValue.isEmpty else { return nil }
  let glyph = activityMarkerPrefix + activity.rawValue
  return set.markup[glyph] == nil ? nil : glyph
}
