/// OperationRequest is one call of a REST or Tile operation, as a generated method hands it to
/// the transport: what the operation declares, and what this call fills in.
package struct OperationRequest: Sendable {
  let facts: OperationFacts
  /// path is the path with every parameter substituted and percent-encoded.
  let path: String
  /// query is the query, in the operation's order.
  let query: [QueryItem]
  /// headers is the headers the caller set, in the operation's order.
  let headers: [HeaderField]
  let body: OperationBody
  /// idempotencyKey is the key the caller passed for a write that declares `Idempotency-Key`,
  /// or nil where it passed none and the transport draws one.
  let idempotencyKey: String?
  /// ifMatch is the tag the caller named for a write that declares `If-Match`, sent as given,
  /// or nil where it named none and nothing is sent.
  let ifMatch: String?
  /// departed is told as each attempt of the call is handed to the exchange, the moment it leaves,
  /// or nil where nobody waits on it: a map's readout makes its tile reads leave in the order it
  /// asks for them by sending each once the one before it has left (`map.readout.open`).
  var departed: (@Sendable () -> Void)?

  /// Creates a request, substituting each path parameter into the operation's template and
  /// dropping each header the caller left unset.
  package init(
    facts: OperationFacts,
    pathParameters: KeyValuePairs<String, String> = [:],
    query: [QueryItem] = [],
    headers: KeyValuePairs<String, String?> = [:],
    body: OperationBody = .none,
    idempotencyKey: String? = nil,
    ifMatch: String? = nil
  ) {
    self.facts = facts
    self.path = OperationPath.substitute(facts.path, with: pathParameters)
    self.query = query
    self.headers = headers.compactMap { name, value in
      value.map { HeaderField(name: name, value: $0) }
    }
    self.body = body
    self.idempotencyKey = idempotencyKey
    self.ifMatch = ifMatch
  }

  /// Creates a request to a path already filled in, carrying the caller's headers as given: a
  /// call to an operation this build prints no method for.
  init(
    facts: OperationFacts,
    query: [QueryItem],
    headerFields: [HeaderField],
    body: OperationBody,
    idempotencyKey: String?,
    ifMatch: String?
  ) {
    self.facts = facts
    self.path = facts.path
    self.query = query
    self.headers = headerFields
    self.body = body
    self.idempotencyKey = idempotencyKey
    self.ifMatch = ifMatch
  }
}
