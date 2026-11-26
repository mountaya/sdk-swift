/// credentialRefusalStatuses are the refusals of access that refuse the credential a request
/// carried: 401, a credential the API does not accept, and 403, a resource the credential may not
/// read. A 402 refuses the organization's agreement, whatever credential asked.
let credentialRefusalStatuses = [401, 403]

/// refusesSupersededCredential tells whether a failure of one of the map's own requests refuses a
/// credential the map has already given up, which is told to nobody, neither as a refusal of access
/// nor as a failure, and starts and keeps no refusal standing (`map.events.access-refused`,
/// `map.events.access-standing`): a 401 or a 403 answering a request that left under a credential
/// the client no longer sends, `superseded`, a session token since replaced or minted after the
/// request left under the key alone, or a visitor's cookie since changed. Telling it would show a
/// refusal at a map's start that the next request lifts. A 402, every other failure, and every
/// failure of a request that left under the credential the client sends are told as they are.
func refusesSupersededCredential(_ status: Int?, superseded: Bool) -> Bool {
  guard superseded, let status else { return false }
  return credentialRefusalStatuses.contains(status)
}
