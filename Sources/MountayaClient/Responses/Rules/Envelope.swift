import Foundation

/// Envelope reads a success: a REST or Tile answer's envelope, and a Data API answer's field.
enum Envelope {
  /// rest reads an envelope's `data` as `Value` and its `extensions.metadata` as `Metadata`.
  ///
  /// The envelope comes back whole, a `data` the contract types as null included. Metadata the
  /// envelope leaves out is nil where `Metadata` is optional, and a decoding failure where the
  /// operation declares it.
  static func rest<Value: Decodable, Metadata: Decodable>(
    _ value: Value.Type,
    metadata: Metadata.Type,
    from body: Data
  ) throws -> (data: Value, metadata: Metadata) {
    let read = try JSONDecoder().decode(Rest<Value, Metadata>.self, from: body)
    return (read.data, read.metadata)
  }

  /// DataAnswer is what a Data API answer holds: its entries, and the operation's own field.
  ///
  /// The body is decoded once: `errors` and `extensions`, the two members the entries and the
  /// metadata are read from, as JSON values, and the operation's field as `Result`, never as JSON
  /// values first, so a long answer, a route of thousands of positions, is read into its type
  /// alone. What the entries say is what `ErrorEnvelope.read(_:)` reads off the whole body.
  struct DataAnswer<Result: Decodable>: Decodable {
    /// read is what the body says of failure.
    let read: ErrorEnvelope.Read
    /// result is the operation's field, or nil where `data` is null or holds no such field.
    let result: Result?

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      read = try Envelope.entries(in: container)
      guard let name = decoder.userInfo[Envelope.operationKey] as? String else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(codingPath: [], debugDescription: "no operation was named"))
      }
      guard container.contains("data"), !(try container.decodeNil(forKey: "data")) else {
        result = nil
        return
      }
      let data = try container.nestedContainer(keyedBy: WireKey.self, forKey: "data")
      guard data.contains(WireKey(stringValue: name)),
        !(try data.decodeNil(forKey: WireKey(stringValue: name)))
      else {
        result = nil
        return
      }
      result = try data.decode(Result.self, forKey: WireKey(stringValue: name))
    }
  }

  /// entries reads what a Data API answer says of failure off its `errors` and its `extensions`,
  /// each decoded as JSON values, and nothing else of the body. It is one function every
  /// operation's answer calls, kept out of line, so an app carries it once rather than once in the
  /// reader of each operation's result.
  @inline(never)
  static func entries(in container: KeyedDecodingContainer<WireKey>) throws
    -> ErrorEnvelope.Read
  {
    var members: [String: JSONValue] = [:]
    for key in ["errors", "extensions"] where container.contains(WireKey(stringValue: key)) {
      members[key] = try container.decode(JSONValue.self, forKey: WireKey(stringValue: key))
    }
    return ErrorEnvelope.read(members)
  }

  /// operationKey is where a decoder is told the field a Data API answer is read for.
  static let operationKey: CodingUserInfoKey = {
    guard let key = CodingUserInfoKey(rawValue: "mountaya.operation") else {
      preconditionFailure("`mountaya.operation` is a key")
    }
    return key
  }()

  /// data reads a Data API answer for the field `operation` names.
  static func data<Result: Decodable>(_ result: Result.Type, operation: String, from body: Data)
    throws -> DataAnswer<Result>
  {
    let decoder = JSONDecoder()
    decoder.userInfo[operationKey] = operation
    return try decoder.decode(DataAnswer<Result>.self, from: body)
  }

  private struct Rest<Value: Decodable, Metadata: Decodable>: Decodable {
    let data: Value
    let metadata: Metadata

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      data = try container.decode(Value.self, forKey: "data")
      if container.contains("extensions"),
        !(try container.decodeNil(forKey: "extensions")),
        case let extensions = try container.nestedContainer(
          keyedBy: WireKey.self, forKey: "extensions"),
        extensions.contains("metadata")
      {
        metadata = try extensions.decode(Metadata.self, forKey: "metadata")
        return
      }
      guard let absent = (Metadata.self as? any ExpressibleByNilLiteral.Type)?.init(nilLiteral: ()),
        let none = absent as? Metadata
      else {
        throw DecodingError.keyNotFound(
          WireKey(stringValue: "metadata"),
          DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription:
              "the operation declares `extensions.metadata`, and the answer carries none"
          )
        )
      }
      metadata = none
    }
  }
}
