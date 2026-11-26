import MountayaClient

/// SearchLabel names one word of a search result's title or second line by the wire value it stands
/// for, so a host's own words, or the localized names its catalogue carries, word it: a place's or
/// a point of interest's category as the Data API spells it, or a way's `highway`, `sac_scale` or
/// `surface` tag as OpenStreetMap spells it, an open vocabulary.
///
/// Two are equal where they name the same value of the same kind, spelled with the same scalars.
public enum SearchLabel: Sendable, Hashable {
  /// placeCategory is a geocoded place's category, as the Data API spells it.
  case placeCategory(DataSchema.PlaceCategory)
  /// poiCategory is a point of interest's category, as the Data API spells it.
  case poiCategory(DataSchema.POICategory)
  /// highway is a way's `highway` tag, as OpenStreetMap spells it: `path`, `track`, `footway`.
  case highway(String)
  /// sacScale is a way's `sac_scale` grade, as OpenStreetMap spells it: `mountain_hiking`,
  /// `alpine_hiking`.
  case sacScale(String)
  /// surface is a way's `surface` tag, worded as the whole token, `gravel surface`, since where the
  /// word goes is the language's.
  case surface(String)

  /// Two labels are equal where they are of one kind and spell their value with the same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.placeCategory(let left), .placeCategory(let right)):
      return sameText(left, right)
    case (.poiCategory(let left), .poiCategory(let right)):
      return sameText(left, right)
    case (.highway(let left), .highway(let right)):
      return sameText(left, right)
    case (.sacScale(let left), .sacScale(let right)):
      return sameText(left, right)
    case (.surface(let left), .surface(let right)):
      return sameText(left, right)
    default:
      return false
    }
  }

  /// hash feeds the kind and the value it names.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .placeCategory(let category):
      hasher.combine(0)
      hasher.combine(category)
    case .poiCategory(let category):
      hasher.combine(1)
      hasher.combine(category)
    case .highway(let tag):
      hasher.combine(2)
      hasher.combine(tag)
    case .sacScale(let grade):
      hasher.combine(3)
      hasher.combine(grade)
    case .surface(let tag):
      hasher.combine(4)
      hasher.combine(tag)
    }
  }
}
