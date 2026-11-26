/// defaultAmenityStackMax is how many badges a stack shows before it counts the rest, where its
/// caller names no other, the `defaultMax` `geo/profile-amenity-stacks.json` declares: four and a
/// count, narrow enough that two checkpoints a kilometer apart do not touch.
public let defaultAmenityStackMax: Double = 4

/// amenityStacks is the stack of services above each pin whose place offers any, in the order the
/// pins are given (`geo.profile.amenity-stacks`).
///
/// The services stack in the order the place states them. The first ones up to `max` are shown,
/// `max` rounded down, none shown below zero or for a maximum that is no number, and the rest are
/// counted. Every service is named in the stack's one label, the counted ones included, so a reader
/// hears the whole list once. A place that offers no service takes no stack.
public func amenityStacks(_ pins: [CurvePin], max: Double = defaultAmenityStackMax)
  -> [AmenityStack]
{
  let shownCount = max >= 0 ? Int(clampNumber(max.rounded(.down), to: 0...Double(Int.max / 2))) : 0
  return pins.compactMap { pin in
    let services = pin.place.details?.amenities ?? []
    guard !services.isEmpty else { return nil }
    let shown = Array(services.prefix(shownCount))
    return AmenityStack(
      pin: pin, shown: shown, counted: services.count - shown.count, named: services)
  }
}
