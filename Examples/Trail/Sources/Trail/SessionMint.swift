import Foundation
import MountayaClient

// trail: trail.client
/// mintSession posts to `address`, `MOUNTAYA_SESSION_URL`, and reads the `Session` it answers:
/// what `postSession` mints for the publishable key, the JSON object the API answers under
/// `data`, as the session server, `mise run trail:session`, answers it, and as your own backend
/// answers it. The secret key that mints it stays on that server.
///
/// It is the mint of Trail's `SessionTokenEngine`, which calls it again before the token expires.
/// An answer other than a success throws `SessionRefused`, and the engine tries again on its own
/// schedule.
func mintSession(at address: URL) async throws -> RestSchema.Session {
  var request = URLRequest(url: address, timeoutInterval: 10)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.httpBody = Data("{}".utf8)
  let (body, response) = try await URLSession.shared.data(for: request)
  let status = (response as? HTTPURLResponse)?.statusCode ?? 0
  guard (200..<300).contains(status) else {
    throw SessionRefused(status: status)
  }
  return try JSONDecoder().decode(RestSchema.Session.self, from: body)
}

/// SessionRefused is a session URL that answered something other than a session.
struct SessionRefused: Error, CustomStringConvertible {
  /// status is the HTTP status it answered.
  let status: Int

  var description: String {
    "The session URL answered \(status)."
  }
}
