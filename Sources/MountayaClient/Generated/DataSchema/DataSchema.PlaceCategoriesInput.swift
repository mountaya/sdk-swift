// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Boolean-per-category filter applied to geocoded place output. Each field
  /// defaults to true, so omitting the input yields raw geocoder results, which is
  /// useful for agentic workflows and third-party API consumers. An interactive map
  /// UI flips categories to false to drop ones it does not want surfaced.
  public struct PlaceCategoriesInput: Sendable, Hashable, Codable {
    /// Include populated places like cities, towns, villages, hamlets, and suburbs. Defaults to
    /// true.
    public var populatedPlace: Bool?
    /// Include administrative boundaries like regions, counties, departments, districts, and
    /// localities. Defaults to true.
    public var administrativeArea: Bool?
    /// Include country-level results such as France or Switzerland. Defaults to true.
    public var country: Bool?
    /// Include natural features like mountain peaks, lakes, glaciers, rivers, and forests. Defaults
    /// to true.
    public var naturalFeature: Bool?
    /// Include transit stations like train stations, bus terminals, airports, and cable car
    /// stations. Defaults to true.
    public var transitStation: Bool?
    /// Include amenities like cafes, restaurants, shops, tourist attractions, and leisure venues.
    /// Defaults to true.
    public var amenity: Bool?
    /// Include addresses like streets, house numbers, and postcodes. Defaults to true.
    public var address: Bool?
    /// Include the catch-all bucket for places that do not fit any of the other categories.
    /// Defaults to true.
    public var other: Bool?

    /// Creates a `PlaceCategoriesInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.populatedPlace = nil
      self.administrativeArea = nil
      self.country = nil
      self.naturalFeature = nil
      self.transitStation = nil
      self.amenity = nil
      self.address = nil
      self.other = nil
      configure(&self)
    }

    /// Reads a `PlaceCategoriesInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.populatedPlace = try container.decodeIfPresent(Bool.self, forKey: "populatedPlace")
      self.administrativeArea = try container.decodeIfPresent(
        Bool.self, forKey: "administrativeArea")
      self.country = try container.decodeIfPresent(Bool.self, forKey: "country")
      self.naturalFeature = try container.decodeIfPresent(Bool.self, forKey: "naturalFeature")
      self.transitStation = try container.decodeIfPresent(Bool.self, forKey: "transitStation")
      self.amenity = try container.decodeIfPresent(Bool.self, forKey: "amenity")
      self.address = try container.decodeIfPresent(Bool.self, forKey: "address")
      self.other = try container.decodeIfPresent(Bool.self, forKey: "other")
    }

    /// Writes a `PlaceCategoriesInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.populatedPlace, forKey: "populatedPlace")
      try container.encodeIfPresent(self.administrativeArea, forKey: "administrativeArea")
      try container.encodeIfPresent(self.country, forKey: "country")
      try container.encodeIfPresent(self.naturalFeature, forKey: "naturalFeature")
      try container.encodeIfPresent(self.transitStation, forKey: "transitStation")
      try container.encodeIfPresent(self.amenity, forKey: "amenity")
      try container.encodeIfPresent(self.address, forKey: "address")
      try container.encodeIfPresent(self.other, forKey: "other")
    }
  }
}
