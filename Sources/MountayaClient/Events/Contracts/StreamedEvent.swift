import Foundation

/// StreamedEvent is an event a stream method hands on, and what the rules of its stream make of
/// each one.
///
/// A conformance names its stream's rules and reads one record into an event, folding the
/// record's `event:` name into its `type` discriminator, so a frame is self-describing once
/// decoded. A record it cannot read, one naming an event it does not know or carrying data it
/// cannot decode, is passed over: it hands the reader nothing and moves no position, so a reopen
/// has it sent again.
package protocol StreamedEvent: Sendable {
  /// rules is the stream's own: when it ends, when it reopens and what counts as progress.
  static var rules: EventStreamRules { get }

  /// rules returns the rules of the stream the operation named `operationId` opens, which are
  /// `rules` but where one vocabulary is read by streams of more than one kind.
  static func rules(for operationId: String) -> EventStreamRules

  /// read returns the event a record carries and the part it plays, or nil where the reader
  /// passes it over.
  static func read(_ record: EventRecord) -> (event: Self, role: EventRole)?

  /// arrivingMember is the user whose arrival the event announces, a collaboration feed's
  /// `presence.join`, or nil for every other event.
  var arrivingMember: String? { get }
}

extension StreamedEvent {
  package static func rules(for operationId: String) -> EventStreamRules {
    rules
  }

  package var arrivingMember: String? {
    nil
  }
}

/// EventRole is the part an event plays in its stream.
package struct EventRole: Sendable, Hashable {
  /// movesPosition is true where the record's `id:` becomes the position a reopen resumes from.
  /// A collaboration feed's live frames carry none, and an id on one moves nothing.
  let movesPosition: Bool
  /// endsStream is true for the event after which nothing is read: an agent run's `done`.
  let endsStream: Bool
  /// isReconnect is true for the `reconnect` event the API writes before it closes a stream whose
  /// credential ended or that it could not keep delivering: no failure, and reopened at once.
  let isReconnect: Bool
  /// isOpeningSnapshot is true for the roster and lock snapshots a collaboration feed's every
  /// open begins with, which are not progress.
  let isOpeningSnapshot: Bool

  /// ordinary is an event that moves the position and plays no other part.
  static let ordinary = EventRole(
    movesPosition: true, endsStream: false, isReconnect: false, isOpeningSnapshot: false)
  /// live is a collaboration feed's live frame, which moves no position.
  static let live = EventRole(
    movesPosition: false, endsStream: false, isReconnect: false, isOpeningSnapshot: false)
  /// openingSnapshot is a live frame a collaboration feed's open begins with.
  static let openingSnapshot = EventRole(
    movesPosition: false, endsStream: false, isReconnect: false, isOpeningSnapshot: true)
  /// end is the event that ends the stream.
  static let end = EventRole(
    movesPosition: true, endsStream: true, isReconnect: false, isOpeningSnapshot: false)
  /// reconnect is the event that asks for a reopen at once.
  static let reconnect = EventRole(
    movesPosition: false, endsStream: false, isReconnect: true, isOpeningSnapshot: false)
}

extension StreamedEvent where Self: Decodable {
  /// decoded reads a record's data as JSON with its `event:` name folded in as `type`, or nil
  /// where it is no JSON object or does not decode.
  static func decoded(_ record: EventRecord) -> Self? {
    guard
      case .object(var members)? = try? JSONDecoder().decode(
        JSONValue.self, from: Data(record.data.utf8))
    else {
      return nil
    }
    if let name = record.event {
      members["type"] = .string(name)
    }
    guard let folded = try? JSONEncoder().encode(JSONValue.object(members)) else { return nil }
    return try? JSONDecoder().decode(Self.self, from: folded)
  }
}
