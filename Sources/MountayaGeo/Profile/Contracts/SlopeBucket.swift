/// SlopeBucket is one bucket of the ramp a profile's own steepness is painted from
/// (`geo.profile.slope-stretches`): every grade from `from` up to the next bucket's, in degrees,
/// signed, so a descent bucket is negative, painted in `color` and read by `key`, a key rather than
/// a word, since a word is the renderer's to write in the reader's language.
///
/// Two are equal where they hold the same number and the same texts, as every value of the geo
/// layer compares.
public struct SlopeBucket: Sendable, Hashable {
  /// from is the lowest grade the bucket holds, in degrees; the first bucket reaches down without
  /// bound.
  public var from: Double
  /// key names the bucket, the word a renderer reads it by: `steepAscent`.
  public var key: String
  /// color is the colour the bucket's stretches are painted in.
  public var color: String

  /// Creates a bucket from its lowest grade, its key and its colour.
  public init(from: Double, key: String, color: String) {
    self.from = from
    self.key = key
    self.color = color
  }

  /// Two buckets are equal where they start at the same number with texts written alike.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.from, rhs.from) && sameText(lhs.key, rhs.key) && sameText(lhs.color, rhs.color)
  }

  /// hash feeds where the bucket starts as the same-number relation reads it, then the texts.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: from)
    hasher.combine(key)
    hasher.combine(color)
  }
}
