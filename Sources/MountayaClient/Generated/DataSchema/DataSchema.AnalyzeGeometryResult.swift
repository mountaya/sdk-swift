// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// The result of `analyzeGeometry`.
  ///
  /// It wraps `GeometryAnalysis` rather than returning it directly, which is how it
  /// carries `duration` beside the analysis without changing the type that
  /// `DirectionsRoute` and `SuggestionRoute` also expose as `analysis`. Every other
  /// query on this API returns a `*Result` for the same reason.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct AnalyzeGeometryResult: Sendable, Hashable, Codable {
    /// The analysis of the submitted geometry: elevation, slope, surface, way type,
    /// trail difficulty and route-level advisories.
    ///
    /// A stretch the routing engine fails to classify on Mountaya's side is reported
    /// as one UNKNOWN segment, as a stretch it has no data for is, and the field then
    /// carries an INTERNAL_ERROR entry in `errors` beside the analysis, which keeps
    /// everything else it read. Such a request is recorded as a failure (5xx), so it
    /// counts toward neither the monthly allowance nor an invoice.
    public var analysis: DataSchema.GeometryAnalysis?
    /// Estimated travel duration of the submitted geometry in seconds, over the
    /// terrain the analysis just read.
    ///
    /// It is the same travel-time model, over the same ground, that `directions` and
    /// `suggestions` report, so a freehand line previewed here and the segment it
    /// becomes agree. Integrating `analysis.speedInfo` over the geometry reproduces
    /// this number exactly. Example: 18720.0 for a 5h12m line.
    public var duration: Double?

    /// Creates a `AnalyzeGeometryResult` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.analysis = nil
      self.duration = nil
      configure(&self)
    }

    /// Reads a `AnalyzeGeometryResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.analysis = try container.decodeIfPresent(
        DataSchema.GeometryAnalysis.self, forKey: "analysis")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
    }

    /// Writes a `AnalyzeGeometryResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.analysis, forKey: "analysis")
      try container.encodeIfPresent(self.duration, forKey: "duration")
    }
  }
}
