import MountayaClient

/// SearchRow is one search result as a list renders it, whatever section it came from.
///
/// `id` is the entity's kind and its own identity (`place:`, `poi:` and `way:` then the
/// OpenStreetMap type and id; `itinerary:`, `collection:` and `zone:` then the id), never a position
/// in a list, so a list keyed by it keeps its rows as a slower section lands. `matched` are the runs
/// of `title` the query emphasizes, as ranges of the title's own indexes on its scalars, empty
/// where it matched none, each read through `title.unicodeScalars`, and `parts` the title cut at
/// them, ready to draw; `activities` are the activities the row advertises, empty where it
/// advertises none.
///
/// Two are equal where every member is, each text and each activity written with the same
/// scalars; `parts` is read from `title` and `matched`, and compares nothing of its own.
public struct SearchRow: Sendable, Hashable, Identifiable {
  /// id is the row's identity: its kind, then the entity's own.
  public var id: String
  /// title is what the row is called.
  public var title: String
  /// matched are the runs of the title the query matched.
  public var matched: [Range<String.Index>]
  /// secondary is the second line, or `nil` for a row that is its title alone.
  public var secondary: SearchRowSecondary?
  /// activities are the activities the row advertises, as glyphs beside it.
  public var activities: [DataSchema.ActivitySlug]
  /// payload is what picking the row hands back.
  public var payload: SearchRowPayload

  /// Creates a row from its identity, its title and the runs of it the query matched, its second
  /// line, the activities it advertises and what picking it hands back.
  public init(
    id: String,
    title: String,
    matched: [Range<String.Index>],
    secondary: SearchRowSecondary?,
    activities: [DataSchema.ActivitySlug],
    payload: SearchRowPayload
  ) {
    self.id = id
    self.title = title
    self.matched = matched
    self.secondary = secondary
    self.activities = activities
    self.payload = payload
  }

  /// parts is the title as the parts a row draws it in: each run `matched` holds, and each run
  /// between them, as the title writes it, scalar for scalar, in order, so the parts joined are the
  /// title (`highlightParts(_:query:)`). A title that matched nothing is one unmatched part. A run
  /// that starts before the one ahead of it ends, or ends past the title, is left unmatched rather
  /// than read, so a row a host wrote by hand draws its title whole.
  public var parts: [HighlightPart] {
    partsOf(title, ranges: matched)
  }

  /// Two rows are equal where every member is, each text compared by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameText(lhs.title, rhs.title) && lhs.matched == rhs.matched
      && lhs.secondary == rhs.secondary && sameText(lhs.activities, rhs.activities)
      && lhs.payload == rhs.payload
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(matched)
    hasher.combine(secondary)
    hasher.combine(activities)
    hasher.combine(payload)
  }
}
