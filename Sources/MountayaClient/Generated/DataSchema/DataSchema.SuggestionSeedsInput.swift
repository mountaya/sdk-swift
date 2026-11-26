// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Seed directives controlling which route candidates the server returns.
  /// Combined with SuggestionsInput.candidates (the total result size), include
  /// pins specific seeds into the result and exclude filters them out of the
  /// fresh candidate pool. A seed appearing in both lists is VALIDATION_FAILED at
  /// ["input", "seeds"]. The caller is responsible for passing the same
  /// start/end/distance/points as the original request when reproducing a seed. The
  /// server does not validate this, and mismatched inputs will produce a different
  /// route even with the same seed.
  public struct SuggestionSeedsInput: Sendable, Hashable, Codable {
    /// Seeds to exclude from the fresh candidate pool, at most 100 (more is
    /// VALIDATION_FAILED at ["input", "seeds", "exclude"]). Any
    /// deterministically-generated seed matching a value in this list is skipped,
    /// so clients can ask for new variations that differ from ones they have
    /// already seen.
    public var exclude: [Int]?
    /// Seeds to pin into the result, in the order provided, each returned as long as
    /// it still routes without crossing a hazard. There may be no more of them than
    /// `candidates`, and none may repeat; either refusal is VALIDATION_FAILED at
    /// ["input", "seeds", "include"]. Any remaining slots are filled with fresh
    /// candidates.
    public var include: [Int]?

    /// Creates a `SuggestionSeedsInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.exclude = nil
      self.include = nil
      configure(&self)
    }

    /// Reads a `SuggestionSeedsInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.exclude = try container.decodeIfPresent([Int].self, forKey: "exclude")
      self.include = try container.decodeIfPresent([Int].self, forKey: "include")
    }

    /// Writes a `SuggestionSeedsInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.exclude, forKey: "exclude")
      try container.encodeIfPresent(self.include, forKey: "include")
    }
  }
}
