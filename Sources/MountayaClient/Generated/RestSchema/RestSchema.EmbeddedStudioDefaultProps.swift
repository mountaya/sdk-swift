// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The organization's starting configuration for Map Publishing: which controls
  /// and panels a visitor of an embed sees, and which units, theme and language
  /// they see them in. These are *proposals*, not limits. Resolution runs URL query
  /// parameter, then this object, then the Mountaya default, so most fields here
  /// can be overridden per embed by the same-named query parameter
  /// (`with_directions_control=false`, `terrain=...`, and so on). Two have no
  /// same-named embed parameter: `with_collection_itineraries` and
  /// `with_collection_zones`, which decide what a collection embed draws. They
  /// are the defaults the Tile API's collection tile falls back to, and a tile
  /// request overrides them with its own `with_itineraries` and `with_zones`
  /// query parameters.
  ///
  /// What a visitor cannot do is exceed `EmbeddedStudioSafetyRules`. Where both
  /// objects carry the same key, the rule caps the default: a rule set to `false`
  /// forces the matching default off for embeds regardless of what is set here.
  /// Everything in this object but those two collection defaults is applied by
  /// the client, which is why capability decisions that must hold against a
  /// hostile caller live in the safety rules instead.
  public struct EmbeddedStudioDefaultProps: Sendable, Hashable, Codable {
    /// Language an embed's interface and place names start in.
    public var preferred_language: RestSchema.Language
    /// Color theme an embed starts in. `auto` follows the visitor's
    /// operating-system preference.
    public var preferred_theme: RestSchema.Theme
    /// Unit distances and elevations are displayed in.
    public var preferred_unit_length: RestSchema.UnitLength
    /// Form travel rates are expressed in. `per-time` renders a speed (km/h with
    /// metric, mph with imperial); `per-distance` renders a pace, the reciprocal
    /// (min/km with metric, min/mi with imperial). The unit *system* still comes
    /// from `preferred_unit_length`; this chooses only the form.
    public var preferred_unit_pace: RestSchema.UnitPace
    /// Unit gradients are displayed in, on both the elevation profile and the
    /// segment readouts.
    public var preferred_unit_slope: RestSchema.UnitSlope
    /// Unit temperatures are displayed in.
    public var preferred_unit_temperature: RestSchema.UnitTemperature
    /// Single color every itinerary segment is painted in on an embed, on both
    /// the map lines and the elevation profile bands. An empty string means each
    /// segment keeps its own color. Applies to an embed only, never to a shared
    /// itinerary view.
    ///
    /// A hex code with a leading hash, in three-digit or six-digit form; a
    /// three-digit value is stored expanded to six digits and lowercased, so
    /// `#F00` is accepted and read back as `#ff0000`. The empty string is the
    /// only other accepted value. Anything else is a 400.
    public var segments_color: String
    /// Slug of the terrain an embed loads first, drawn from the terrain
    /// catalog the tiles API's layers manifest publishes. Only the
    /// initial selection: a visitor may switch to any terrain `with_terrains`
    /// permits. A slug absent from the manifest leaves the map on the Mountaya
    /// default terrain.
    public var terrain: String
    /// Visual style the terrain starts in, for terrains that publish both a light
    /// and a dark rendering.
    public var terrain_variant: RestSchema.TerrainVariant
    /// Whether the stretches of an itinerary's route whose access is restricted
    /// are drawn, as stripes and a warning icon per kind, read from the
    /// `itinerary_restrictions` layer of the itinerary tiles. No safety rule
    /// governs it.
    public var with_access_restrictions: Bool
    /// Whether a collection embed draws the itineraries the collection contains.
    /// It is the default a collection tile request without `with_itineraries`
    /// falls back to. Capped by `safety_rules.with_collection_itineraries`,
    /// which withholds the layer server-side when false.
    public var with_collection_itineraries: Bool
    /// Whether a collection embed draws the zones the collection contains,
    /// which are its published public zones, each as last published, since the
    /// embed reads as the public does. It is the default a collection tile
    /// request without `with_zones` falls back to.
    /// Capped by `safety_rules.with_collection_zones`, which withholds the layer
    /// server-side when false.
    public var with_collection_zones: Bool
    /// Whether the directions control is offered, opening the turn-by-turn
    /// directions of the itinerary's routed segments as they were stored, to
    /// read, print or download as a PDF. It computes no route: a visitor never
    /// routes between points of their own. No safety rule governs it.
    public var with_directions_control: Bool
    /// Whether the export control is offered, letting a visitor download an
    /// itinerary in any of the export formats (GPX, FIT, TCX, GeoJSON, KML, KMZ
    /// and CSV). No safety rule governs it.
    public var with_download_control: Bool
    /// Whether the map navigation controls, the zoom and compass buttons, are
    /// shown. An embed never offers geolocation, whatever this says, because it
    /// never asks a visitor for their location. No safety rule governs it; the
    /// zoom range a visitor can actually reach is set by
    /// `safety_rules.zoom_min` and `safety_rules.zoom_max`.
    public var with_navigation_control: Bool
    /// Slugs of the terrain overlays offered in the overlay picker. **An empty
    /// array, or one holding the entry `"*"` anywhere, offers the whole
    /// catalog**; any other
    /// list narrows the picker to those slugs and drops a category left with
    /// nothing to show. Note that this is a display list only and its empty case
    /// reads the OPPOSITE way from `safety_rules.with_overlays`, where an empty
    /// array denies every overlay. An overlay offered here but absent from the
    /// safety rule renders no tiles.
    public var with_overlays: [String]
    /// Whether the overlay time cursor is offered, letting a visitor move an
    /// overlay backwards or forwards in time. Capped by
    /// `safety_rules.with_overlays_control`, which, when false, refuses a tile
    /// asked for more than 15 minutes from the current instant on every overlay
    /// the server draws per instant.
    ///
    /// It governs the time cursor alone. It neither offers nor hides the layers
    /// control: which overlays a visitor may switch on and off is
    /// `with_overlays`, capped by `safety_rules.with_overlays`, and which
    /// terrains the switcher offers is `with_terrains`, so an embed whose
    /// overlays are drawn only at the present instant still offers every overlay
    /// its cap admits.
    public var with_overlays_control: Bool
    /// Whether the preferences control is offered, letting a visitor change the
    /// units (distance, travel rate, slope and temperature) and the interface
    /// language for their visit. The theme is not among them: an embed keeps
    /// the publisher's `preferred_theme`. No safety rule governs it; it never
    /// persists anything to the organization.
    public var with_preferences_control: Bool
    /// Whether the profile's computed terrain analysis is shown: the surface
    /// and way-type bars under the elevation chart, and the surface, way type,
    /// trail difficulty, slope and aspect readings of its hover readout. Capped by
    /// `safety_rules.with_profile_analysis`, which strips the analysis from the
    /// payload server-side when false, so turning this on against a false rule
    /// shows nothing.
    ///
    /// Read AGAINST `with_profile_elevation`: on a pointer device the bars are
    /// revealed by hovering the elevation curve and are aligned to its distance
    /// axis, so the analysis shows nothing while the chart is off.
    public var with_profile_analysis: Bool
    /// Whether the itinerary's summary characteristics (distance, ascent,
    /// descent, duration) are shown alongside the profile. No safety rule governs
    /// it.
    public var with_profile_characteristics: Bool
    /// Whether the elevation profile chart is shown. Capped by
    /// `safety_rules.with_profile_elevation`, which forces the control off and
    /// disables it when false.
    public var with_profile_elevation: Bool
    /// Whether the pace control is offered on the elevation profile, letting a
    /// visitor enter their own travel rate and read the itinerary re-timed for
    /// it. Resolution runs URL query parameter, then this object, then the
    /// Mountaya default, like the rest of this object. The override is
    /// session-local and persists nothing: the itinerary's committed speeds are
    /// untouched, every other visitor reads the author's figures, and clearing
    /// the field restores them. No safety rule governs it; the re-time reveals
    /// nothing a visitor cannot already read.
    ///
    /// Requires BOTH `with_profile_elevation` and `with_profile_characteristics`,
    /// for two different reasons. The chart, because the rate is read against the
    /// curve it re-times. The characteristics row, because that row is WHERE the
    /// field renders, beside the segment chooser. With either of them off the
    /// field is withheld however the embed is configured.
    public var with_profile_pace_control: Bool
    /// Whether the street-level imagery control is offered. No safety rule
    /// governs it.
    public var with_streetview_control: Bool
    /// Slugs of the terrains offered in the terrain switcher. **An empty array,
    /// or one holding the entry `"*"` anywhere, offers every terrain in the
    /// manifest**; any
    /// other list narrows the switcher to those slugs. This is the one allowlist
    /// with no safety rule behind it. Enforcement is client-side only, which is
    /// why it sits here rather than on `EmbeddedStudioSafetyRules`: terrain tiles
    /// carry no organization-private data, so restricting the switcher is a
    /// presentation choice, not a security boundary. Treat it accordingly.
    public var with_terrains: [String]

    /// Creates a `EmbeddedStudioDefaultProps` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      preferred_language: RestSchema.Language,
      preferred_theme: RestSchema.Theme,
      preferred_unit_length: RestSchema.UnitLength,
      preferred_unit_pace: RestSchema.UnitPace,
      preferred_unit_slope: RestSchema.UnitSlope,
      preferred_unit_temperature: RestSchema.UnitTemperature,
      segments_color: String,
      terrain: String,
      terrain_variant: RestSchema.TerrainVariant,
      with_access_restrictions: Bool,
      with_collection_itineraries: Bool,
      with_collection_zones: Bool,
      with_directions_control: Bool,
      with_download_control: Bool,
      with_navigation_control: Bool,
      with_overlays: [String],
      with_overlays_control: Bool,
      with_preferences_control: Bool,
      with_profile_analysis: Bool,
      with_profile_characteristics: Bool,
      with_profile_elevation: Bool,
      with_profile_pace_control: Bool,
      with_streetview_control: Bool,
      with_terrains: [String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.preferred_language = preferred_language
      self.preferred_theme = preferred_theme
      self.preferred_unit_length = preferred_unit_length
      self.preferred_unit_pace = preferred_unit_pace
      self.preferred_unit_slope = preferred_unit_slope
      self.preferred_unit_temperature = preferred_unit_temperature
      self.segments_color = segments_color
      self.terrain = terrain
      self.terrain_variant = terrain_variant
      self.with_access_restrictions = with_access_restrictions
      self.with_collection_itineraries = with_collection_itineraries
      self.with_collection_zones = with_collection_zones
      self.with_directions_control = with_directions_control
      self.with_download_control = with_download_control
      self.with_navigation_control = with_navigation_control
      self.with_overlays = with_overlays
      self.with_overlays_control = with_overlays_control
      self.with_preferences_control = with_preferences_control
      self.with_profile_analysis = with_profile_analysis
      self.with_profile_characteristics = with_profile_characteristics
      self.with_profile_elevation = with_profile_elevation
      self.with_profile_pace_control = with_profile_pace_control
      self.with_streetview_control = with_streetview_control
      self.with_terrains = with_terrains
      configure(&self)
    }

    /// Reads a `EmbeddedStudioDefaultProps` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.preferred_language = try container.decode(
        RestSchema.Language.self, forKey: "preferred_language")
      self.preferred_theme = try container.decode(RestSchema.Theme.self, forKey: "preferred_theme")
      self.preferred_unit_length = try container.decode(
        RestSchema.UnitLength.self, forKey: "preferred_unit_length")
      self.preferred_unit_pace = try container.decode(
        RestSchema.UnitPace.self, forKey: "preferred_unit_pace")
      self.preferred_unit_slope = try container.decode(
        RestSchema.UnitSlope.self, forKey: "preferred_unit_slope")
      self.preferred_unit_temperature = try container.decode(
        RestSchema.UnitTemperature.self, forKey: "preferred_unit_temperature")
      self.segments_color = try container.decode(String.self, forKey: "segments_color")
      self.terrain = try container.decode(String.self, forKey: "terrain")
      self.terrain_variant = try container.decode(
        RestSchema.TerrainVariant.self, forKey: "terrain_variant")
      self.with_access_restrictions = try container.decode(
        Bool.self, forKey: "with_access_restrictions")
      self.with_collection_itineraries = try container.decode(
        Bool.self, forKey: "with_collection_itineraries")
      self.with_collection_zones = try container.decode(Bool.self, forKey: "with_collection_zones")
      self.with_directions_control = try container.decode(
        Bool.self, forKey: "with_directions_control")
      self.with_download_control = try container.decode(Bool.self, forKey: "with_download_control")
      self.with_navigation_control = try container.decode(
        Bool.self, forKey: "with_navigation_control")
      self.with_overlays = try container.decode([String].self, forKey: "with_overlays")
      self.with_overlays_control = try container.decode(Bool.self, forKey: "with_overlays_control")
      self.with_preferences_control = try container.decode(
        Bool.self, forKey: "with_preferences_control")
      self.with_profile_analysis = try container.decode(Bool.self, forKey: "with_profile_analysis")
      self.with_profile_characteristics = try container.decode(
        Bool.self, forKey: "with_profile_characteristics")
      self.with_profile_elevation = try container.decode(
        Bool.self, forKey: "with_profile_elevation")
      self.with_profile_pace_control = try container.decode(
        Bool.self, forKey: "with_profile_pace_control")
      self.with_streetview_control = try container.decode(
        Bool.self, forKey: "with_streetview_control")
      self.with_terrains = try container.decode([String].self, forKey: "with_terrains")
    }

    /// Writes a `EmbeddedStudioDefaultProps` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.preferred_language, forKey: "preferred_language")
      try container.encode(self.preferred_theme, forKey: "preferred_theme")
      try container.encode(self.preferred_unit_length, forKey: "preferred_unit_length")
      try container.encode(self.preferred_unit_pace, forKey: "preferred_unit_pace")
      try container.encode(self.preferred_unit_slope, forKey: "preferred_unit_slope")
      try container.encode(self.preferred_unit_temperature, forKey: "preferred_unit_temperature")
      try container.encode(self.segments_color, forKey: "segments_color")
      try container.encode(self.terrain, forKey: "terrain")
      try container.encode(self.terrain_variant, forKey: "terrain_variant")
      try container.encode(self.with_access_restrictions, forKey: "with_access_restrictions")
      try container.encode(self.with_collection_itineraries, forKey: "with_collection_itineraries")
      try container.encode(self.with_collection_zones, forKey: "with_collection_zones")
      try container.encode(self.with_directions_control, forKey: "with_directions_control")
      try container.encode(self.with_download_control, forKey: "with_download_control")
      try container.encode(self.with_navigation_control, forKey: "with_navigation_control")
      try container.encode(self.with_overlays, forKey: "with_overlays")
      try container.encode(self.with_overlays_control, forKey: "with_overlays_control")
      try container.encode(self.with_preferences_control, forKey: "with_preferences_control")
      try container.encode(self.with_profile_analysis, forKey: "with_profile_analysis")
      try container.encode(
        self.with_profile_characteristics, forKey: "with_profile_characteristics")
      try container.encode(self.with_profile_elevation, forKey: "with_profile_elevation")
      try container.encode(self.with_profile_pace_control, forKey: "with_profile_pace_control")
      try container.encode(self.with_streetview_control, forKey: "with_streetview_control")
      try container.encode(self.with_terrains, forKey: "with_terrains")
    }
  }
}
