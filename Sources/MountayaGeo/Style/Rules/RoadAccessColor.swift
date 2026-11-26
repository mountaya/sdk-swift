/// roadAccessColor is the colour a restricted stretch of `kind` is drawn in: its stripes along a
/// route and the disc its warning icon stands on (`map.icons.stripe-pattern`).
///
/// A kind the vocabulary gains is a case this rule does not compile without, never a stretch
/// drawn in no colour.
public func roadAccessColor(_ kind: RoadAccessKind) -> HexColor {
  switch kind {
  case .forbidden: HexColor(hex: "#e03131")
  case .private: HexColor(hex: "#e8590c")
  case .permit: HexColor(hex: "#9c36b5")
  case .service: HexColor(hex: "#1971c2")
  case .localAccess: HexColor(hex: "#0c8599")
  case .restricted: HexColor(hex: "#495057")
  }
}
