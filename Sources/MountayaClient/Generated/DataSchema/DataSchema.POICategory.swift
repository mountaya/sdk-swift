// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Point-of-interest category. Classifies POIs surfaced by search and on the
  /// map by their primary outdoor function.
  ///
  /// Six members (VIEWPOINT, PARKING, TOILETS, SHELTER, CABLE_CAR and
  /// ACCOMMODATION) are spelled the same as members of WaypointAmenity, and the
  /// two are not interchangeable. This enum says what a place *is*; WaypointAmenity
  /// says what a waypoint *offers*. A hut POI is HUT here and may offer
  /// ACCOMMODATION there. Do not map one enum onto the other by name.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct POICategory: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Mountain hut or refuge providing shelter and meals.
    public static let hut: Self = "HUT"
    /// Mountain summit or peak.
    public static let peak: Self = "PEAK"
    /// Mountain pass or col between valleys.
    public static let pass: Self = "PASS"
    /// Scenic viewpoint or panorama spot.
    public static let viewpoint: Self = "VIEWPOINT"
    /// Parking area for vehicles, often at a trailhead.
    public static let parking: Self = "PARKING"
    /// Drinkable water source such as a spring or fountain.
    public static let waterSource: Self = "WATER_SOURCE"
    /// Cafe or coffee shop.
    public static let cafe: Self = "CAFE"
    /// Restaurant serving meals.
    public static let restaurant: Self = "RESTAURANT"
    /// Supermarket or grocery store.
    public static let supermarket: Self = "SUPERMARKET"
    /// Pharmacy or chemist.
    public static let pharmacy: Self = "PHARMACY"
    /// Public toilets.
    public static let toilets: Self = "TOILETS"
    /// Campsite or camping pitch.
    public static let campsite: Self = "CAMPSITE"
    /// Bivouac shelter or emergency refuge with no staff.
    public static let shelter: Self = "SHELTER"
    /// Cable car, gondola, or chairlift station.
    public static let cableCar: Self = "CABLE_CAR"
    /// Bus station or major bus stop.
    public static let busStation: Self = "BUS_STATION"
    /// Train station.
    public static let trainStation: Self = "TRAIN_STATION"
    /// Airport or airfield.
    public static let airport: Self = "AIRPORT"
    /// Hotel, hostel, guest house, or chalet.
    public static let accommodation: Self = "ACCOMMODATION"
    /// Caravan or camper site.
    public static let caravanSite: Self = "CARAVAN_SITE"
    /// Hospital.
    public static let hospital: Self = "HOSPITAL"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
