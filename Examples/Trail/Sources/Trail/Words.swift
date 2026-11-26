import MountayaGeo

/// Words is what Trail writes on screen, the same English in the three native SDKs' Trail.
enum Words {
  /// notice stands in place of the map and the search where no publishable key is set.
  static let notice =
    "Add your publishable key to see the map. See the README, Examples you can run."

  /// mapRefused is the notice a map the API refuses shows.
  static let mapRefused = "The map was refused: check the key's tiles scope."

  /// searchNeedsSession is what a disabled search box says, the contract's own words.
  static let searchNeedsSession = "Search needs a session token (MOUNTAYA_SESSION_URL)"

  /// replay is the switch that walks the route in place of the device's positions.
  static let replay = "Replay"

  /// start is the control that starts following the itinerary.
  static let start = "Start"

  /// stop is the control that ends the navigation.
  static let stop = "Stop"

  /// arrived is what the screen shows once the traveller has arrived at the end of the route.
  static let arrived = "You have arrived"

  /// details labels the handle that opens the sheet onto the itinerary's tables, and closes it.
  static let details = "Itinerary details"

  /// progress is what is left of the route, `<distance> left · <duration> · arrive at <time>`,
  /// each part left out where it is nil or empty.
  static func progress(distance: String, duration: String?, arrival: String?) -> String {
    var parts = ["\(distance) left"]
    if let duration, !duration.isEmpty {
      parts.append(duration)
    }
    if let arrival {
      parts.append("arrive at \(arrival)")
    }
    return parts.joined(separator: " · ")
  }
}

// trail: trail.voice
/// sentence is the sentence Trail shows and says for `instruction`: every key of the closed set its
/// own words, with no default case, so a key the contract adds fails to compile here rather than
/// going unsaid. A key is said with the way's or the waypoint's `name`, or plain, its `Plain`
/// twin, and a roundabout with its `exit`.
func sentence(for instruction: NavigationInstruction) -> String {
  let name = instruction.name ?? ""
  let exit = instruction.exit ?? 0
  switch instruction.key {
  case .continue: return "Continue on \(name)"
  case .continuePlain: return "Continue straight"
  case .depart: return "Head out on \(name)"
  case .departPlain: return "Head out"
  case .enterRoundabout: return "Enter the roundabout onto \(name)"
  case .enterRoundaboutPlain: return "Enter the roundabout"
  case .exitRoundabout: return "Exit the roundabout onto \(name)"
  case .exitRoundaboutPlain: return "Exit the roundabout"
  case .goal: return "Arrive at your destination on \(name)"
  case .goalPlain: return "Arrive at your destination"
  case .keepLeft: return "Keep left onto \(name)"
  case .keepLeftPlain: return "Keep left"
  case .keepRight: return "Keep right onto \(name)"
  case .keepRightPlain: return "Keep right"
  case .roundaboutExit: return "At the roundabout, take exit \(exit) onto \(name)"
  case .roundaboutExitPlain: return "At the roundabout, take exit \(exit)"
  case .sharpLeft: return "Make a sharp left onto \(name)"
  case .sharpLeftPlain: return "Make a sharp left"
  case .sharpRight: return "Make a sharp right onto \(name)"
  case .sharpRightPlain: return "Make a sharp right"
  case .slightLeft: return "Bear left onto \(name)"
  case .slightLeftPlain: return "Bear left"
  case .slightRight: return "Bear right onto \(name)"
  case .slightRightPlain: return "Bear right"
  case .turnLeft: return "Turn left onto \(name)"
  case .turnLeftPlain: return "Turn left"
  case .turnRight: return "Turn right onto \(name)"
  case .turnRightPlain: return "Turn right"
  case .unknown: return "Continue on \(name)"
  case .unknownPlain: return "Continue"
  case .uturn: return "Make a U-turn onto \(name)"
  case .uturnPlain: return "Make a U-turn"
  case .waypoint: return "Pass \(name)"
  case .waypointPlain: return "Pass a waypoint"
  }
}
