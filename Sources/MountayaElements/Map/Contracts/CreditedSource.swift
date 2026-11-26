/// CreditedSource is a source of a map's style as its credit is read (`map.style.attribution`): the
/// credit it states, which may be absent or blank, and whether a layer draws it at the camera's
/// zoom.
struct CreditedSource: Sendable, Equatable {
  /// attribution is the credit the source states, or nil where it states none.
  let attribution: String?
  /// isDrawn is whether a layer of the style draws the source at the camera's zoom.
  let isDrawn: Bool
}
