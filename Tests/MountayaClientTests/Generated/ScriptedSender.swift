import Foundation

@testable import MountayaClient

/// ScriptedSender is the seam a test puts behind the generated methods: it records each call as
/// it reaches the seam and answers it from a canned JSON body, so a printed method is held to
/// the contract with no network.
///
/// A call with no answer queued is recorded and then refused with `Unanswered`, which is how a
/// test that reads only the request leaves the answer out. An event stream's method awaits
/// nothing, so the calls are kept under a lock every method records through, the stream's from
/// outside the actor.
actor ScriptedSender: OperationSending {
  /// Sent is one call as it reached the seam.
  struct Sent: Sendable {
    let facts: OperationFacts
    /// request is the REST or Tile request, or nil for a Data API call.
    let request: OperationRequest?
    /// operation is the Data API operation, or nil for a REST or Tile call.
    let operation: DataOperation?
    let options: RequestOptions
    /// json is the body or the input as JSON, keys sorted, or nil where there is none.
    let json: String?
    let select: FieldSelection?
  }

  /// Unanswered is the failure of a call no answer was queued for.
  struct Unanswered: Error {}

  /// sent is every call, in the order each reached the seam.
  var sent: [Sent] { log.value }
  private let log = Locked<[Sent]>([])
  private var answers: [String]
  private let frames: [(id: String?, json: String)]
  private let file: BinaryResponse?

  init(
    answers: [String] = [],
    frames: [(id: String?, json: String)] = [],
    file: BinaryResponse? = nil
  ) {
    self.answers = answers
    self.frames = frames
    self.file = file
  }

  /// client is a client sending through this seam.
  nonisolated var client: Mountaya {
    Mountaya(sender: self)
  }

  /// json writes a value as JSON with its keys sorted, so a test compares stable text.
  static func json(_ value: any Encodable) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return String(decoding: try encoder.encode(value), as: UTF8.self)
  }

  /// decode reads a value from JSON text.
  static func decode<Value: Decodable>(_ type: Value.Type, from text: String) throws -> Value {
    try JSONDecoder().decode(type, from: Data(text.utf8))
  }

  func envelope<Value: Decodable & Sendable, Metadata: Decodable & Sendable>(
    _ request: OperationRequest,
    options: RequestOptions
  ) async throws -> Response<Value, Metadata> {
    try record(request, options: options)
    let envelope = try Self.decode(CannedEnvelope<Value, Metadata>.self, from: try nextAnswer())
    return Response(data: envelope.data, metadata: envelope.metadata)
  }

  func binary(_ request: OperationRequest, options: RequestOptions) async throws
    -> BinaryResponse
  {
    try record(request, options: options)
    guard let file else { throw Unanswered() }
    return file
  }

  nonisolated func events<Event: StreamedEvent>(
    _ request: OperationRequest,
    options: RequestOptions
  ) throws -> EventStream<Event> {
    try record(request, options: options)
    let frames = frames.compactMap { frame in
      Event.read(EventRecord(event: nil, data: frame.json, id: frame.id)).map {
        EventFrame(id: frame.id, event: $0.event)
      }
    }
    return EventStream(frames: frames)
  }

  func query<Input: Encodable & Sendable, Result: Decodable & Sendable>(
    _ operation: DataOperation,
    facts: OperationFacts,
    input: Input,
    select: FieldSelection?,
    options: RequestOptions
  ) async throws -> Result {
    let call = Sent(
      facts: facts,
      request: nil,
      operation: operation,
      options: options,
      json: try Self.json(input),
      select: select
    )
    log.withLock { $0.append(call) }
    return try Self.decode(Result.self, from: try nextAnswer())
  }

  private nonisolated func record(_ request: OperationRequest, options: RequestOptions) throws {
    var json: String?
    if case .json(let body) = request.body {
      json = try Self.json(body)
    }
    let call = Sent(
      facts: request.facts,
      request: request,
      operation: nil,
      options: options,
      json: json,
      select: nil
    )
    log.withLock { $0.append(call) }
  }

  private func nextAnswer() throws -> String {
    guard !answers.isEmpty else { throw Unanswered() }
    return answers.removeFirst()
  }
}

/// CannedEnvelope reads a canned answer as the envelope a REST or Tile success is: `data`, and
/// `extensions.metadata` where the operation declares one.
private struct CannedEnvelope<Value: Decodable, Metadata: Decodable>: Decodable {
  let data: Value
  let metadata: Metadata

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: WireKey.self)
    data = try container.decode(Value.self, forKey: "data")
    let extensions = try? container.nestedContainer(keyedBy: WireKey.self, forKey: "extensions")
    if let extensions, extensions.contains("metadata") {
      metadata = try extensions.decode(Metadata.self, forKey: "metadata")
    } else if let absent = Metadata.self as? any ExpressibleByNilLiteral.Type,
      let metadata = absent.init(nilLiteral: ()) as? Metadata
    {
      self.metadata = metadata
    } else {
      throw DecodingError.keyNotFound(
        WireKey(stringValue: "metadata"),
        .init(codingPath: decoder.codingPath, debugDescription: "no metadata")
      )
    }
  }
}
