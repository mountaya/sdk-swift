import Foundation

@testable import MountayaClient

/// ScriptedSender is the seam a test puts behind the admin unit's printed methods: it records each
/// call as it reaches the core's seam, the one the unit sends through, and answers it from a canned
/// JSON body, so a printed method is held to the contract with no network.
///
/// Every operation of the admin unit answers an envelope, so a file, a stream or a Data API call
/// reaching it is refused with `Unanswered`, as a call with no answer queued is once recorded.
actor ScriptedSender: OperationSending {
  /// Sent is one call as it reached the seam.
  struct Sent: Sendable {
    let request: OperationRequest
    let options: RequestOptions
    /// json is the body as JSON, keys sorted, or nil where there is none.
    let json: String?
  }

  /// Unanswered is the failure of a call no answer was queued for.
  struct Unanswered: Error {}

  private(set) var sent: [Sent] = []
  private var answers: [String]

  init(answers: [String] = []) {
    self.answers = answers
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
    var json: String?
    if case .json(let body) = request.body {
      json = try Self.json(body)
    }
    sent.append(Sent(request: request, options: options, json: json))
    guard !answers.isEmpty else { throw Unanswered() }
    let envelope = try Self.decode(
      CannedEnvelope<Value, Metadata>.self, from: answers.removeFirst())
    return Response(data: envelope.data, metadata: envelope.metadata)
  }

  func binary(_ request: OperationRequest, options: RequestOptions) async throws
    -> BinaryResponse
  {
    throw Unanswered()
  }

  nonisolated func events<Event: StreamedEvent>(
    _ request: OperationRequest,
    options: RequestOptions
  ) throws -> EventStream<Event> {
    throw Unanswered()
  }

  func query<Input: Encodable & Sendable, Result: Decodable & Sendable>(
    _ operation: DataOperation,
    facts: OperationFacts,
    input: Input,
    select: FieldSelection?,
    options: RequestOptions
  ) async throws -> Result {
    throw Unanswered()
  }
}

/// CannedEnvelope reads a canned answer as the envelope a REST success is: `data`, and
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
