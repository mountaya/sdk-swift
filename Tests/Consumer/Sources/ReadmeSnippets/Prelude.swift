import Foundation
import MountayaClient

/// fetchSessionFromYourBackend stands for an app's own endpoint, the one the README's snippets
/// name without declaring: it mints a session token with the secret key the app never holds, and
/// answers what `postSession` answers.
func fetchSessionFromYourBackend() async throws -> RestSchema.Session {
  RestSchema.Session(expires_at: Date(timeIntervalSince1970: 0), user_id: nil, token: "sess_2c3d")
}

/// webhookSecret stands for an endpoint's signing secret, which the README's snippets name without
/// declaring: a server keeps it in its own configuration, and never in an app.
let webhookSecret = "whsk_8f3c2a71b845d0e4c7a6b3f180d92e5a17c4e9b0d36f2a58e1c7b4093d6a2f15"
