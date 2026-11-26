/// HeaderField is one header a caller sets on a request, such as `Last-Event-ID` on an event
/// stream. The credential's headers are not among them: the transport projects those.
struct HeaderField: Sendable, Hashable {
  let name: String
  let value: String
}
