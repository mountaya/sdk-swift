// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Timing published for a waypoint: the instant a participant must have left it
  /// by, and how long they are expected to spend there. Null when the waypoint
  /// carries no timing.
  ///
  /// A cut-off is an absolute instant and nothing else: one spelling of the rule,
  /// so no reader has to decide between two.
  public struct WaypointTiming: Sendable, Hashable, Codable {
    /// Absolute wall-clock instant by which this waypoint must be left. Null when
    /// the waypoint has no cut-off.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var cutoff_at: Date??
    /// Time expected to be spent at this waypoint, in seconds: a hut stop, an aid
    /// station or a scheduled break, at most thirty days. Null when no stop is
    /// planned.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var stop_duration: Int??

    /// Creates a `WaypointTiming` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.cutoff_at = nil
      self.stop_duration = nil
      configure(&self)
    }

    /// Reads a `WaypointTiming` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.cutoff_at = try container.decodeWiredMerge(Date.self, forKey: "cutoff_at")
      self.stop_duration = try container.decodeMerge(Int.self, forKey: "stop_duration")
    }

    /// Writes a `WaypointTiming` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWiredMerge(self.cutoff_at, forKey: "cutoff_at")
      try container.encodeMerge(self.stop_duration, forKey: "stop_duration")
    }
  }
}
