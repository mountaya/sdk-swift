/// accessRefusalStatuses are the HTTP statuses that refuse access, the `refusalStatuses`
/// `map/events-access-refused.json` declares: 401 for a credential the API does not accept, 402 for
/// an entitlement the agreement does not include, 403 for a resource the credential may not read.
let accessRefusalStatuses = [401, 402, 403]

/// accessRefusalStatus is the status a failure of one of the map's own requests carries where it
/// refuses access, and nil where it is a fault (`map.events.access-refused`): any other status, a
/// missing tile or a server error, and none at all, a request that never reached the API, are told
/// as failures, which a map recovers from.
func accessRefusalStatus(_ status: Int?) -> Int? {
  guard let status, accessRefusalStatuses.contains(status) else { return nil }
  return status
}
