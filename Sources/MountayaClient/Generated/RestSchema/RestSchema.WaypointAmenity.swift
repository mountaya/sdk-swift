// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A service or facility available at a waypoint. An amenity is a fact about the
  /// place, independent of the `icon` the author chose to draw it with: a waypoint
  /// drawn with a `hut` icon may offer `water`, `hot-meal` and `accommodation`, and
  /// the two vocabularies never substitute for one another.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WaypointAmenity: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Drinking water available, from a tap, spring or refill point.
    public static let water: Self = "water"
    /// Non-water drinks served, such as tea, coffee or soft drinks.
    public static let drinks: Self = "drinks"
    /// Solid food available, without implying a cooked meal.
    public static let food: Self = "food"
    /// A cooked, hot meal is served.
    public static let hotMeal: Self = "hot-meal"
    /// Light snacks, bars or fruit available.
    public static let snacks: Self = "snacks"
    /// Staffed medical post with qualified personnel.
    public static let medical: Self = "medical"
    /// First-aid kit or basic care available, not necessarily staffed.
    public static let firstAid: Self = "first-aid"
    /// Public toilets.
    public static let toilets: Self = "toilets"
    /// Showers or washing facilities.
    public static let showers: Self = "showers"
    /// Drop bags may be deposited or collected here.
    public static let dropBag: Self = "drop-bag"
    /// Luggage may be left in storage, beyond race drop bags.
    public static let luggageStorage: Self = "luggage-storage"
    /// Personal assistance or a support crew is permitted here.
    public static let assistance: Self = "assistance"
    /// A dedicated area to sit and recover.
    public static let restArea: Self = "rest-area"
    /// Beds or overnight accommodation available.
    public static let accommodation: Self = "accommodation"
    /// Unstaffed shelter from weather, such as a bothy or refuge.
    public static let shelter: Self = "shelter"
    /// Tents may be pitched here.
    public static let camping: Self = "camping"
    /// Picnic tables or an outdoor eating area.
    public static let picnic: Self = "picnic"
    /// A shop where supplies can be bought.
    public static let shop: Self = "shop"
    /// Vehicle parking available.
    public static let parking: Self = "parking"
    /// A shuttle service serves this point.
    public static let shuttle: Self = "shuttle"
    /// Public transport, such as a bus or train, serves this point.
    public static let publicTransport: Self = "public-transport"
    /// A cable car, gondola or chairlift serves this point.
    public static let cableCar: Self = "cable-car"
    /// Electric bike or vehicle charging available.
    public static let powerCharging: Self = "power-charging"
    /// Wireless internet access available.
    public static let wifi: Self = "wifi"
    /// Reliable mobile network coverage at this point.
    public static let mobileSignal: Self = "mobile-signal"
    /// Waste and recycling disposal available.
    public static let waste: Self = "waste"
    /// Dogs or other pets are allowed here.
    public static let petFriendly: Self = "pet-friendly"
    /// Reachable and usable by wheelchair.
    public static let wheelchairAccess: Self = "wheelchair-access"
    /// A notable view or scenic overlook.
    public static let viewpoint: Self = "viewpoint"
    /// Timing is recorded here, such as a chip mat or manual check-in.
    public static let timingCheckpoint: Self = "timing-checkpoint"

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
