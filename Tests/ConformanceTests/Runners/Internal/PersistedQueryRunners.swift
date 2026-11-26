import Foundation
import GateSupport

@testable import MountayaClient

extension InternalRunners {
  /// dataApqDigest answers with a document's digest, after holding the rule to the fixture's
  /// constants.
  static let dataApqDigest = Runner(id: "transport.data.apq-digest", table: .internal) {
    fixture, fixtureCase in
    let constants = fixture.constants ?? .object([])
    guard try constants.string(at: "algorithm") == "SHA-256",
      try constants.string(at: "bytes") == "utf-8",
      try constants.string(at: "encoding") == "lowercase-hex",
      try constants.integer(at: "extensionVersion") == PersistedQueryDigest.version
    else {
      throw FixtureError(description: "the fixture's constants are not the rule's")
    }
    let document = try fixtureCase.input.string(at: "document")
    return .value(.string(PersistedQueryDigest.digest(of: document)))
  }

  /// dataApqRefusal answers with what the errors a digest-only attempt was answered with mean,
  /// `null` where they are an ordinary failure, after holding the rule's spellings to the
  /// fixture's.
  ///
  /// The answer is read as the transport reads a Data API answer, under the case's `status`, 200
  /// where it states none, so a refusal is read off the errors before the status makes the answer
  /// a failure: what it means is the attempt the transport sends next, the document alone for a
  /// declined protocol and the document beside the digest for one to register, and none for an
  /// ordinary failure.
  ///
  /// A case naming a `registration` reads it as the answer to the attempt that follows a request
  /// for the document, the document beside its digest, and answers what that answer means, read as
  /// the first answer's is: a declined protocol is read there, and a request for the document and
  /// the Data API's entry are not.
  ///
  /// A case asking about the `next-call` answers instead with what the first attempt of the
  /// next operation on the same transport sends after that answer. A case whose digest was
  /// `rejected` is one whose first operation could not compute it, so that operation sent its
  /// document alone and the errors answer that; the next operation sends the same document and
  /// computes its digest again.
  static let dataApqRefusal = Runner(id: "transport.data.apq-refusal", table: .internal) {
    fixture, fixtureCase in
    let constants = fixture.constants ?? .object([])
    let declared: [(String, Set<String>)] = [
      ("registerMessages", PersistedQueryRefusal.registerMessages),
      ("registerCodes", Set(PersistedQueryRefusal.registerCodes.map(\.rawValue))),
      ("unsupportedMessages", PersistedQueryRefusal.unsupportedMessages),
      ("unsupportedCodes", Set(PersistedQueryRefusal.unsupportedCodes.map(\.rawValue))),
    ]
    for (key, spellings) in declared
    where Set(try constants.array(at: key).compactMap(\.stringValue)) != spellings {
      throw FixtureError(description: "the fixture's `\(key)` are not the rule's")
    }
    let entries = try constants.array(at: "unsupportedEntries").map {
      entry throws(FixtureError) in
      "\(try entry.string(at: "code")) \(try entry.string(at: "message"))"
    }
    guard
      Set(entries)
        == Set(
          PersistedQueryRefusal.unsupportedEntries.map { "\($0.code.rawValue) \($0.message)" }),
      try constants.string(at: "unsupportedScope") == "transport-lifetime",
      try constants.string(at: "rejectedDigestScope") == "dropped-not-remembered"
    else {
      throw FixtureError(description: "the fixture's entries or scopes are not the rule's")
    }

    let input = fixtureCase.input
    let errors = try input.array(at: "errors")
    let status = try input.optionalInteger(at: "status") ?? 200
    let document = DataOperation.directions.document
    let digest: String?
    switch try input.optionalString(at: "digest") {
    case nil: digest = PersistedQueryDigest.digest(of: document)
    case "rejected": digest = nil
    case let other?: throw FixtureError(description: "no digest is `\(other)`")
    }
    let transport = Transport(
      configuration: Transport.Configuration(
        credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc"),
        language: nil,
        baseUrls: .standard,
        retry: .standard,
        timeout: AttemptBudget.clientDefault,
        onResponse: nil
      ),
      exchange: MapFixtures.Recording(answer: .failing),
      sleeper: ClockSleeper(clock: HeldSeams.Still()),
      wallClock: HeldSeams.wallClock,
      random: HeldSeams.Draws()
    )
    let attempt = transport.persistedQueries.value.firstAttempt(digest: digest)
    let call = try transport.prepare(
      .directions,
      path: OperationFacts.directions.path,
      query: [],
      headers: [],
      body: .json(JSONValue.null),
      accept: "application/json",
      idempotencyKey: nil,
      ifMatch: nil,
      options: RequestOptions()
    )
    func answer(_ errors: [OrderedJSON]) -> Transport.Answer {
      Transport.Answer(
        status: status,
        headers: [:],
        body: Data(
          OrderedJSON.object([OrderedJSON.Member(key: "errors", value: .array(errors))])
            .serialized().utf8)
      )
    }
    var answered = attempt
    var read: Transport.Settled<Transport.DataOutcome<JSONValue>> = transport.readData(
      answer(errors), of: call, operation: .directions, attempt: attempt)
    if let registration = input["registration"] {
      guard case .success(.resend(let next)) = read, next.digest != nil, next.sendsDocument else {
        throw FixtureError(description: "a registration follows no request for the document")
      }
      guard let entries = registration.elements else {
        throw FixtureError(description: "the registration's answer is not a list of errors")
      }
      answered = next
      read = transport.readData(answer(entries), of: call, operation: .directions, attempt: next)
    }
    var refusal: String?
    if case .success(.resend(let next)) = read {
      guard answered.digest != nil, next.sendsDocument else {
        throw FixtureError(description: "a resend that is no answer to an attempt with a digest")
      }
      refusal = next.digest == nil ? "unsupported" : "register"
    }

    switch try input.optionalString(at: "ask") {
    case nil:
      return .value(refusal.map(OrderedJSON.string) ?? .null)
    case "next-call":
      let next = transport.persistedQueries.value.firstAttempt(
        digest: PersistedQueryDigest.digest(of: document))
      return .value(
        .object([
          OrderedJSON.Member(key: "sendsDigest", value: .bool(next.digest != nil)),
          OrderedJSON.Member(key: "sendsDocument", value: .bool(next.sendsDocument)),
        ])
      )
    case let other?:
      throw FixtureError(description: "no question is `\(other)`")
    }
  }
}
