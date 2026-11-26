// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One day's Tile API usage, for one kind of resource, from one surface, in one
  /// status class. A day on which a resource was served from both the embed and
  /// the API, or both succeeded and failed, yields one point per combination
  /// rather than one total: a client that wants the combined figure adds them,
  /// and a client that wants what the monthly allowance counts reads the `2xx`
  /// points of the `api` and `embedding` surfaces, the only ones counted.
  public struct UsageTilePoint: Sendable, Hashable, Codable {
    /// The day the figure covers, as a UTC calendar day.
    public var date: String
    /// What the requests asked for.
    public var resource_type: AdminSchema.UsageTileResourceType
    /// Where the requests came from.
    public var surface: AdminSchema.UsageTileSurface
    /// How the requests ended, so availability is read from the same payload as
    /// the volume the monthly allowance counts.
    public var status_class: AdminSchema.UsageStatusClass
    /// How many requests this combination covers.
    public var requests: Int64

    /// Creates a `UsageTilePoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      date: String,
      resource_type: AdminSchema.UsageTileResourceType,
      surface: AdminSchema.UsageTileSurface,
      status_class: AdminSchema.UsageStatusClass,
      requests: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.date = date
      self.resource_type = resource_type
      self.surface = surface
      self.status_class = status_class
      self.requests = requests
      configure(&self)
    }

    /// Reads a `UsageTilePoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.date = try container.decode(String.self, forKey: "date")
      self.resource_type = try container.decode(
        AdminSchema.UsageTileResourceType.self, forKey: "resource_type")
      self.surface = try container.decode(AdminSchema.UsageTileSurface.self, forKey: "surface")
      self.status_class = try container.decode(
        AdminSchema.UsageStatusClass.self, forKey: "status_class")
      self.requests = try container.decode(Int64.self, forKey: "requests")
    }

    /// Writes a `UsageTilePoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.date, forKey: "date")
      try container.encode(self.resource_type, forKey: "resource_type")
      try container.encode(self.surface, forKey: "surface")
      try container.encode(self.status_class, forKey: "status_class")
      try container.encode(self.requests, forKey: "requests")
    }
  }
}
