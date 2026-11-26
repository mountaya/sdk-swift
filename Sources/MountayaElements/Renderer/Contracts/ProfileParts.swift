#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  /// ProfileParts is the parts an `ItineraryProfile` draws beside its curve and its stat strip,
  /// which it always draws. Each part is off until named, but the amenities, which the itinerary's
  /// data switch on, so `standard` holds them alone.
  public struct ProfileParts: OptionSet, Sendable, Hashable {
    /// rawValue is the parts as bits.
    public let rawValue: Int

    /// Creates the parts the bits of `rawValue` name.
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// amenities stacks each pinned place's services above its pin (`geo.profile.amenity-stacks`).
    public static let amenities = ProfileParts(rawValue: 1 << 0)
    /// sections states each leg under the chart as a chip (`geo.profile.section-chips`).
    public static let sections = ProfileParts(rawValue: 1 << 1)
    /// tooltip shows a card at the cursor stating what it stands on (`geo.profile.cursor-readout`),
    /// the stat strip then stating the itinerary's own figures.
    public static let tooltip = ProfileParts(rawValue: 1 << 2)
    /// navigator draws the whole itinerary under the chart with the window drawn marked on it,
    /// whose handles a reader drags to zoom (`geo.profile.window-clamp`).
    public static let navigator = ProfileParts(rawValue: 1 << 3)
    /// elevationAxis labels the chart at its floor, its middle and its ceiling
    /// (`geo.profile.domain`).
    public static let elevationAxis = ProfileParts(rawValue: 1 << 4)
    /// distanceAxis labels the distance under the chart, and names the places that divide the
    /// itinerary, a crowded name left out (`geo.profile.axis-label-culling`).
    public static let distanceAxis = ProfileParts(rawValue: 1 << 5)

    /// standard is what a profile draws where the app names nothing: the amenities.
    public static let standard: ProfileParts = [.amenities]
  }
#endif
