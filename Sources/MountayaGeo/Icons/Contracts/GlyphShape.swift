/// GlyphShape is one shape a renderer builds from an icon's markup: its element name, lowercase,
/// and the attributes it keeps, keyed lowercase, a group's transform folded into its own.
///
/// Two are equal where they hold the same tag and the same attributes, every name and value
/// written with the same scalars. The attributes are a dictionary, so their order is not kept: a
/// renderer reads each by its name.
public struct GlyphShape: Sendable, Hashable {
  /// tag is the shape's element name, lowercase: `path`, `circle`, `rect` and the like.
  public var tag: String
  /// attributes are the attributes the shape keeps, each a member of `glyphAttributes`, keyed
  /// lowercase.
  public var attributes: [String: String]

  /// Creates a shape from its element name and the attributes it keeps.
  public init(tag: String, attributes: [String: String]) {
    self.tag = tag
    self.attributes = attributes
  }

  /// Two shapes are equal where their tags and their attributes are written with the same
  /// scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.tag, rhs.tag) && sameText(lhs.attributes, rhs.attributes)
  }

  /// hash feeds the tag and the attributes, in no order.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(tag)
    hasher.combine(attributes)
  }
}
