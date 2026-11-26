#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import MountayaGeo

  /// ProfileColoring is how an `ItineraryProfile` paints its curve and the area under it
  /// (`geo.profile.curve-stops`): in the accent alone, in stretches the app coloured, by the
  /// itinerary's own steepness, or in stretches the app classified, whose word the cursor's readout
  /// names.
  public enum ProfileColoring: Sendable, Hashable {
    /// plain paints the whole curve in the accent.
    case plain
    /// stretches paints each stretch in its colour, ground no stretch covers in the accent.
    case stretches([CurveColor])
    /// slope paints the itinerary's own steepness, bucketed by `buckets`, Geo's own ramp,
    /// `slopeBuckets`, where none are given (`geo.profile.slope-stretches`), each named by the
    /// scope's `profile.slope` word for its key.
    case slope([SlopeBucket] = slopeBuckets)
    /// classes paints stretches the app classified, each named by its own word.
    case classes([ProfileClass])
  }
#endif
