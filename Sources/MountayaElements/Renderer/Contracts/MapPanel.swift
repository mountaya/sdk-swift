#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  /// MapPanel names a panel a control stack opens: one the stack ships, `layers`, `pois` or
  /// `preferences`, or one of the app's own, by a name of its own (`PanelControl`). A stack holds
  /// one panel open at a time.
  ///
  /// Two are equal where their names are written with the same scalars.
  public struct MapPanel: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    /// layers is the base-map and overlay picker (`LayersPanel`).
    public static let layers: MapPanel = "layers"
    /// pois is the points-of-interest picker (`POIPanel`).
    public static let pois: MapPanel = "pois"
    /// preferences is the units and language picker (`PreferencesPanel`).
    public static let preferences: MapPanel = "preferences"

    /// rawValue is the panel's name.
    public let rawValue: String

    /// Creates the panel `rawValue` names.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates the panel a string literal names.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// Two panels are the same where their names are written with the same scalars.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.rawValue.unicodeScalars.elementsEqual(rhs.rawValue.unicodeScalars)
    }

    /// hash feeds the name's scalars.
    public func hash(into hasher: inout Hasher) {
      for scalar in rawValue.unicodeScalars {
        hasher.combine(scalar)
      }
    }
  }
#endif
