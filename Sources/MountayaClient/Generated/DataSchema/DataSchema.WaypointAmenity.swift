// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A service or facility available at a waypoint. An amenity is a fact about the
  /// place, independent of the icon its author chose to draw it with: a waypoint drawn
  /// as a hut may offer WATER, HOT_MEAL and ACCOMMODATION, and the two vocabularies
  /// never substitute for one another.
  ///
  /// Six members (VIEWPOINT, PARKING, TOILETS, SHELTER, CABLE_CAR and
  /// ACCOMMODATION) are also POICategory members. That enum classifies what a place
  /// is; this one lists what a waypoint offers. Matching names do not mean matching
  /// meanings, so do not map one onto the other.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WaypointAmenity: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Drinking water available, from a tap, spring or refill point.
    public static let water: Self = "WATER"
    /// Non-water drinks served, such as tea, coffee or soft drinks.
    public static let drinks: Self = "DRINKS"
    /// Solid food available, without implying a cooked meal.
    public static let food: Self = "FOOD"
    /// A cooked, hot meal is served.
    public static let hotMeal: Self = "HOT_MEAL"
    /// Light snacks, bars or fruit available.
    public static let snacks: Self = "SNACKS"
    /// Staffed medical post with qualified personnel.
    public static let medical: Self = "MEDICAL"
    /// First-aid kit or basic care available, not necessarily staffed.
    public static let firstAid: Self = "FIRST_AID"
    /// Public toilets.
    public static let toilets: Self = "TOILETS"
    /// Showers or washing facilities.
    public static let showers: Self = "SHOWERS"
    /// Drop bags may be deposited or collected here.
    public static let dropBag: Self = "DROP_BAG"
    /// Luggage may be left in storage, beyond race drop bags.
    public static let luggageStorage: Self = "LUGGAGE_STORAGE"
    /// Personal assistance or a support crew is permitted here.
    public static let assistance: Self = "ASSISTANCE"
    /// A dedicated area to sit and recover.
    public static let restArea: Self = "REST_AREA"
    /// Beds or overnight accommodation available.
    public static let accommodation: Self = "ACCOMMODATION"
    /// Unstaffed shelter from weather, such as a bothy or refuge.
    public static let shelter: Self = "SHELTER"
    /// Tents may be pitched here.
    public static let camping: Self = "CAMPING"
    /// Picnic tables or an outdoor eating area.
    public static let picnic: Self = "PICNIC"
    /// A shop where supplies can be bought.
    public static let shop: Self = "SHOP"
    /// Vehicle parking available.
    public static let parking: Self = "PARKING"
    /// A shuttle service serves this point.
    public static let shuttle: Self = "SHUTTLE"
    /// Public transport, such as a bus or train, serves this point.
    public static let publicTransport: Self = "PUBLIC_TRANSPORT"
    /// A cable car, gondola or chairlift serves this point.
    public static let cableCar: Self = "CABLE_CAR"
    /// Electric bike or vehicle charging available.
    public static let powerCharging: Self = "POWER_CHARGING"
    /// Wireless internet access available.
    public static let wifi: Self = "WIFI"
    /// Reliable mobile network coverage at this point.
    public static let mobileSignal: Self = "MOBILE_SIGNAL"
    /// Waste and recycling disposal available.
    public static let waste: Self = "WASTE"
    /// Dogs or other pets are allowed here.
    public static let petFriendly: Self = "PET_FRIENDLY"
    /// Reachable and usable by wheelchair.
    public static let wheelchairAccess: Self = "WHEELCHAIR_ACCESS"
    /// A notable view or scenic overlook.
    public static let viewpoint: Self = "VIEWPOINT"
    /// Timing is recorded here, such as a chip mat or manual check-in.
    public static let timingCheckpoint: Self = "TIMING_CHECKPOINT"

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
