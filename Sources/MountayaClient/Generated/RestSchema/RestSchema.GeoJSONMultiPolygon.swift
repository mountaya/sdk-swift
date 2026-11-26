// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GeoJSON MultiPolygon geometry (RFC 7946). `coordinates` is a list of Polygon
  /// coordinate arrays.
  public typealias GeoJSONMultiPolygon = MountayaClient.GeoJSONMultiPolygon
}
