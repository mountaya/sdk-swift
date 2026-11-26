/// LayersPanelPress is what a press on a row of a layers picker asks for
/// (`geo.layers.picker-rows`): the command of the row's choice with the row's slug, which the
/// layers selection carries out, or, for a row showing its lock, the report that the entry was
/// pressed, which selects nothing.
///
/// Two are equal where they are of one kind and hold the same, a slug by its scalars.
public enum LayersPanelPress: Sendable, Hashable {
  /// command is the selection's command for `choice`, with the entry's slug.
  case command(LayersPanelChoice, slug: String)
  /// locked is the report that the entry `slug` names, out of the viewer's reach, was pressed.
  case locked(String)

  /// Two presses are equal where they are of one kind and hold the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.command(let a, let aSlug), .command(let b, let bSlug)): a == b && sameText(aSlug, bSlug)
    case (.locked(let a), .locked(let b)): sameText(a, b)
    default: false
    }
  }

  /// hash feeds the kind and what it holds.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .command(let choice, let slug):
      hasher.combine(0)
      hasher.combine(choice)
      hasher.combine(slug)
    case .locked(let slug):
      hasher.combine(1)
      hasher.combine(slug)
    }
  }
}
