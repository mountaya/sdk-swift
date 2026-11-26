// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One day's data usage, for one operation, on one surface, on one metric, in
  /// one status class. A day on which an operation both succeeded and failed yields one
  /// point per class rather than one total, so availability is read from the same
  /// payload as the volume that counts, which is the `requests` figures of class
  /// `2xx` alone, one per root field answered without an error, what a monthly
  /// allowance counts and what a self-serve organization is invoiced for (the
  /// per-minute limit counts HTTP requests instead): every other metric measures work inside a
  /// request and is reported, not counted. A failed request records `requests`
  /// alone: the other metrics count work that did not happen. Only the `api` and
  /// `mcp` surfaces count; `studio-online` and `studio-embedded` are reported and
  /// never counted.
  public struct UsageDataPoint: Sendable, Hashable, Codable {
    /// The day the figure covers, as a UTC calendar day.
    public var date: String
    /// Which Data API operation the figure belongs to.
    public var resource_type: AdminSchema.UsageDataResourceType
    /// Where the usage was made: a Data API request from one of the
    /// organization's own clients, a request through Mountaya's MCP server, or
    /// the work Map Studio in Mountaya's web application or an Embedded Studio
    /// did, which is reported and never counted.
    public var surface: AdminSchema.UsageDataSurface
    /// What this figure counts, which decides how to read `value`.
    public var metric: AdminSchema.UsageMetric
    /// How the requests ended, so availability is read from the same payload as
    /// the volume that counts.
    public var status_class: AdminSchema.UsageStatusClass
    /// How much of the metric this combination covers.
    public var value: Int64

    /// Creates a `UsageDataPoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      date: String,
      resource_type: AdminSchema.UsageDataResourceType,
      surface: AdminSchema.UsageDataSurface,
      metric: AdminSchema.UsageMetric,
      status_class: AdminSchema.UsageStatusClass,
      value: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.date = date
      self.resource_type = resource_type
      self.surface = surface
      self.metric = metric
      self.status_class = status_class
      self.value = value
      configure(&self)
    }

    /// Reads a `UsageDataPoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.date = try container.decode(String.self, forKey: "date")
      self.resource_type = try container.decode(
        AdminSchema.UsageDataResourceType.self, forKey: "resource_type")
      self.surface = try container.decode(AdminSchema.UsageDataSurface.self, forKey: "surface")
      self.metric = try container.decode(AdminSchema.UsageMetric.self, forKey: "metric")
      self.status_class = try container.decode(
        AdminSchema.UsageStatusClass.self, forKey: "status_class")
      self.value = try container.decode(Int64.self, forKey: "value")
    }

    /// Writes a `UsageDataPoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.date, forKey: "date")
      try container.encode(self.resource_type, forKey: "resource_type")
      try container.encode(self.surface, forKey: "surface")
      try container.encode(self.metric, forKey: "metric")
      try container.encode(self.status_class, forKey: "status_class")
      try container.encode(self.value, forKey: "value")
    }
  }
}
