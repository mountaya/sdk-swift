// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Icon displayed on a point-of-interest or point waypoint. `flag-start` and
  /// `flag-end` are the start and end markers the itinerary's vector tiles draw at
  /// the two ends of its route: they appear only in those tiles, never on a
  /// waypoint read, and a write that sends either is a 400.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WaypointIcon: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Warning or alert.
    public static let circleWarning: Self = "circle-warning"
    /// Announcement or notice.
    public static let megaphone: Self = "megaphone"
    /// Accommodation or sleeping place.
    public static let bed: Self = "bed"
    /// Building or shelter.
    public static let apartmentBuilding: Self = "apartment-building"
    /// Caravan or camper parking.
    public static let camperVan: Self = "camper-van"
    /// Checkpoint or validation point.
    public static let circleCheck: Self = "circle-check"
    /// Parking area.
    public static let parkingSign: Self = "parking-sign"
    /// Medical or first-aid point.
    public static let medicalCross: Self = "medical-cross"
    /// Water source or hydration point.
    public static let droplet: Self = "droplet"
    /// Viewpoint or scenic overlook.
    public static let eye: Self = "eye"
    /// Flag marker or milestone.
    public static let flag: Self = "flag"
    /// Start marker of an itinerary, drawn in its vector tiles only.
    public static let flagStart: Self = "flag-start"
    /// End marker of an itinerary, drawn in its vector tiles only.
    public static let flagEnd: Self = "flag-end"
    /// Mountain hut or private accommodation.
    public static let hut: Self = "hut"
    /// Information point.
    public static let circleInfo: Self = "circle-info"
    /// Generic map pin.
    public static let mapPin: Self = "map-pin"
    /// Camping or tent area.
    public static let camping: Self = "camping"
    /// Summit or achievement point.
    public static let trophy: Self = "trophy"
    /// Food or restaurant.
    public static let cutlery: Self = "cutlery"
    /// Bus stop serving the route.
    public static let bus: Self = "bus"
    /// Railway station serving the route.
    public static let train: Self = "train"
    /// Cable car, gondola or chairlift.
    public static let cableCar: Self = "cable-car"
    /// Electric bike or vehicle charging point.
    public static let chargingStation: Self = "charging-station"
    /// Gate or barrier across the route.
    public static let gate: Self = "gate"
    /// Public toilets.
    public static let toilet: Self = "toilet"
    /// Showers or washing facilities.
    public static let shower: Self = "shower"
    /// Waste disposal point.
    public static let trash: Self = "trash"
    /// Shop or resupply point.
    public static let shop: Self = "shop"
    /// Picnic or rest area.
    public static let picnic: Self = "picnic"
    /// Helicopter landing or evacuation zone.
    public static let helicopter: Self = "helicopter"
    /// Emergency call point or mobile coverage note.
    public static let signal: Self = "signal"
    /// Climbing or roped technical section.
    public static let climbing: Self = "climbing"
    /// Fixed ladder, cable or via ferrata section.
    public static let ladder: Self = "ladder"

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
