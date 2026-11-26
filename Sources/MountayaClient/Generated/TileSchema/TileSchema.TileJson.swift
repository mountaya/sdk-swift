// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// A tile source described by a TileJSON document
  /// (https://github.com/mapbox/tilejson-spec), ready to hand to a map renderer
  /// unmodified: where its tiles are fetched from, its zoom range, its bounds and
  /// its attribution. Its `tiles` templates point at this API, so a renderer that
  /// registers the source reaches its tiles through this API alone, under the
  /// credential it sends here, and no address in it carries a credential of
  /// Mountaya's.
  ///
  /// The document is the TileJSON format rather than this contract's, so its
  /// members are not declared here, and a member that format adds reaches a
  /// client unchanged. It declares its own version in its `tilejson` member: the
  /// version the base-map provider's document carries, which Mountaya does not
  /// set. The elevation source's document also carries the `encoding` its pixels
  /// are decoded with.
  public typealias TileJson = [String: JSONValue]
}
