// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A feature of Map Studio a person may use in one organization, as
  /// `getMyOrganizations` answers it on each membership in
  /// `studio_entitlements`. Each names a feature rather than a tier, so an
  /// agreement that covers some features and leaves others out is stated
  /// exactly, and a studio reads these from its host's viewer rather than
  /// deciding them from the products an organization holds.
  ///
  /// They follow from what the organization holds and from the member's role. A
  /// member of an organization whose agreement includes Map Studio holds every
  /// one of them but six: `copilot`, which a `viewer` does not hold, `embed`,
  /// `publish`, `video-export` and `video-organization-modes`, which take Map
  /// Publishing as well, since each is part of publishing a map, and
  /// `white-label`, which takes White label as well. A member of an organization
  /// without Map Studio holds `map-pois` alone.
  /// Under a publishable key, `map-overlays`, `map-pois` and `profile-insights`
  /// also follow the organization's safety rules, as `studio_entitlements` on a
  /// membership says.
  ///
  /// They show or withhold what a studio offers and authorize nothing: every
  /// request is still refused by its own rule, so an answer read before a change
  /// of agreement only offers or withholds a feature until the next read.
  ///
  /// A member is kebab-case, as every enum member on this surface is: the
  /// surface and the feature joined by a hyphen where the feature belongs to a
  /// surface, and the feature alone where it is the surface.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct StudioEntitlement: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The link to a place's external page in the map's context menu.
    public static let contextMenuInsights: Self = "context-menu-insights"
    /// The co-pilot, with its conversations and its runs. A run also needs the organization's AI
    /// provider configuration, which the run itself answers for.
    public static let copilot: Self = "copilot"
    /// Embedding an itinerary or a collection in another site, through Mountaya's hosted embed,
    /// which needs Map Publishing.
    public static let embed: Self = "embed"
    /// The overlays and enrichments drawn over the base map, the points of interest aside, with the
    /// timestamp scrubber that steps through them.
    public static let mapOverlays: Self = "map-overlays"
    /// The points of interest, their groups and their overlay menu, and a waypoint picked from one
    /// of them.
    public static let mapPois: Self = "map-pois"
    /// The enrichment bands of the elevation profile.
    public static let profileInsights: Self = "profile-insights"
    /// Publishing an itinerary or a zone, downloading an itinerary's draft as a file, and the ways
    /// into an embed, each of which needs Map Publishing. A studio offers none of them without it
    /// rather than offer what is refused with a `402`. It is held whatever the member's role, and
    /// publishing also asks for a role that writes, which `postItineraryPublication` and
    /// `postZonePublication` check.
    public static let publish: Self = "publish"
    /// Exporting an itinerary as a video, which needs Map Publishing.
    public static let videoExport: Self = "video-export"
    /// The modes and presets of a video export beyond the plain one, which needs Map Publishing as
    /// `video-export` does.
    public static let videoOrganizationModes: Self = "video-organization-modes"
    /// The Mountaya mark comes off the video preview and the frames of an exported video. Tile
    /// attribution is a licence obligation and stays on every map.
    public static let whiteLabel: Self = "white-label"

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
