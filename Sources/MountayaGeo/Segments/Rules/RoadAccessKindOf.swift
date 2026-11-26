import MountayaClient

/// roadAccessValueKinds is the kind each access value the contract names is shown as, keyed by the
/// value as REST spells it. A value of no kind maps to nil: `permissive`, `agricultural` and
/// `forestry` grant passage or are ordinary terrain on foot, which is information and never a
/// hazard. A value it does not name is shown as `RoadAccessKind.restricted` by
/// `roadAccessKindOf(_:)`.
///
/// Its values are optional, so a subscript reads a double optional: nil for a value the table does
/// not name, and `.some(nil)` for one it names as of no kind.
public let roadAccessValueKinds: [RestSchema.RoadAccessRestrictionType: RoadAccessKind?] = [
  .no: .forbidden,
  .private: .private,
  .permit: .permit,
  .service: .service,
  .destination: .localAccess,
  .customers: .localAccess,
  .delivery: .localAccess,
  .restricted: .restricted,
  .unknown: .restricted,
  .permissive: nil,
  .agricultural: nil,
  .forestry: nil,
]

/// unnamedValueKind is the kind of a value `roadAccessValueKinds` does not name, so a restriction
/// the vocabulary gains later is still shown as one.
private let unnamedValueKind = RoadAccessKind.restricted

/// roadAccessKindOf returns the kind a stretch is shown as from the access `values` REST answers for
/// it: the most severe kind among them, whatever their order, or nil where no value names one, an
/// empty list included.
///
/// Each value reads through `roadAccessValueKinds`, a value it does not name as
/// `RoadAccessKind.restricted`. A value is read in either surface's spelling, its ASCII capitals
/// folded and nothing else, never by a locale's case rules, and matched by its scalars: `PRIVATE`
/// is `private`, and ` private` is a value the table does not name.
public func roadAccessKindOf(_ values: [RestSchema.RoadAccessRestrictionType]) -> RoadAccessKind? {
  mostSevereKind(values.map(\.rawValue))
}

/// roadAccessKindOf returns the kind a stretch is shown as from the access `values` the Data API
/// answers for it, by the rule REST's values are read by: the Data API's `PRIVATE` is REST's
/// `private`.
public func roadAccessKindOf(_ values: [DataSchema.RoadAccessRestrictionType]) -> RoadAccessKind? {
  mostSevereKind(values.map(\.rawValue))
}

/// mostSevereKind is the most severe kind among values spelled `spellings`, or nil where none
/// names one.
private func mostSevereKind(_ spellings: [String]) -> RoadAccessKind? {
  var mostSevere: RoadAccessKind?
  for spelling in spellings {
    guard let kind = kindOf(spelling) else { continue }
    if let held = mostSevere, held <= kind { continue }
    mostSevere = kind
  }
  return mostSevere
}

/// kindOf is the kind a value names in either surface's spelling, or nil where it names none.
private func kindOf(_ value: String) -> RoadAccessKind? {
  let key = RestSchema.RoadAccessRestrictionType(rawValue: asciiLowercase(value))
  // A dictionary finds a key by canonical equivalence; a value is matched by its scalars.
  guard let index = roadAccessValueKinds.index(forKey: key),
    sameText(roadAccessValueKinds[index].key, key)
  else { return unnamedValueKind }
  return roadAccessValueKinds[index].value
}
