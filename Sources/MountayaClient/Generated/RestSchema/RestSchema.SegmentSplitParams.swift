// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for splitting a segment in two.
  ///
  /// The split point is given as a fraction of the segment's length, not as a
  /// coordinate. A fraction is engine-independent, exactly expressible, and
  /// eliminates the whole class of "the point is not on the line" failures a
  /// coordinate would introduce: the client snaps its map click to the polyline and
  /// converts it to a fraction, and the server projects that fraction back onto the
  /// stored geometry. The server refuses a split that lands within 10 m of either
  /// endpoint, since a small fraction is degenerate on a short segment.
  ///
  /// The two halves may be named by the client. Naming is the client's concern
  /// because the server cannot compose copy in the caller's language; it enforces
  /// the same length constraint as every other segment name.
  public struct SegmentSplitParams: Sendable, Hashable, Codable {
    /// Display name for the first half, the one that keeps the original segment's
    /// identifier. Omit to leave the original's name unchanged. 2 to 30
    /// characters as sent; leading and trailing whitespace is then trimmed, and
    /// what remains must still be at least 2 characters. A name is one line: a
    /// tab, a line break or a line separator between two of its characters is a
    /// `400`, and one at either end is trimmed with the whitespace there.
    public var first_name: String?
    /// Position of the split along the segment, as a fraction of its length in
    /// the open interval (0, 1). 0.5 splits it in half.
    public var fraction: Double
    /// Display name for the second half, the segment created after the first.
    /// Omit to inherit the original's name. 2 to 30 characters as sent; leading
    /// and trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var second_name: String?

    /// Creates a `SegmentSplitParams` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      fraction: Double,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.first_name = nil
      self.fraction = fraction
      self.second_name = nil
      configure(&self)
    }

    /// Reads a `SegmentSplitParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.first_name = try container.decodeIfPresent(String.self, forKey: "first_name")
      self.fraction = try container.decode(Double.self, forKey: "fraction")
      self.second_name = try container.decodeIfPresent(String.self, forKey: "second_name")
    }

    /// Writes a `SegmentSplitParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.first_name, forKey: "first_name")
      try container.encode(self.fraction, forKey: "fraction")
      try container.encodeIfPresent(self.second_name, forKey: "second_name")
    }
  }
}
