import MountayaClient

/// statedMembers returns the members of a patch that state a value, which is how a patch is read
/// before it is merged onto what a map holds (`map.engine.patch`).
///
/// A member written as `nil` is unstated: it names nothing, which is what a caller forwards where
/// it may not have a value, and it leaves the member held as it is. Every other member is kept as
/// written, JSON's `null`, `false`, `0` and the empty string included, since each is a value a
/// member may give a meaning of its own: a paint property set to `null` goes back to the style's
/// default. Merged over what is held, the answer replaces each member it states and adds one the
/// map did not hold.
func statedMembers(_ patch: [String: JSONValue?]) -> [String: JSONValue] {
  var stated: [String: JSONValue] = [:]
  for (name, member) in patch {
    if let value = member {
      stated[name] = value
    }
  }
  return stated
}
