import Foundation
import MountayaAdmin
import MountayaClient
import Testing

/// The admin unit as a server and an admin tool call it: through `import MountayaAdmin` and the
/// public surface alone, `mountaya.admin` declared on the core's client, every request leaving
/// through the client's transport with the credential the core projects.
@Suite("Admin unit")
struct AdminUnitTests {
  /// Recorder answers every attempt with `body` and keeps what each sent.
  private actor Recorder: HTTPExchange {
    private(set) var sent: [ExchangeRequest] = []
    private let body: String

    init(body: String) {
      self.body = body
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request)
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(body.utf8)))
    }
  }

  #if os(macOS) || os(Linux)
    @Test("a server mints a session token through the unit, under the core's secret key")
    func mint() async throws {
      let recorder = Recorder(
        body: #"{"data": {"expires_at": "2026-03-14T09:26:53.000Z", "token": "sess_9f", "#
          + #""user_id": "u1"}}"#)
      let mountaya = try Mountaya(
        credential: .secret(key: "sk_test_a"), retry: try RetryPolicy(maxRetries: 0),
        exchange: recorder)

      let minted = try await mountaya.admin.sessions.postSession(
        body: .init(publishable_key: "pk_test_a") { $0.user_id = "u1" })

      let sent = try #require(await recorder.sent.first)
      #expect(sent.method == "POST")
      #expect(sent.url.path == "/v1/sessions")
      #expect(sent.header("X-API-Key") == "sk_test_a")
      #expect(sent.header("X-Session-Token") == nil)
      let body = try JSONSerialization.jsonObject(with: try #require(sent.body))
      #expect(body as? [String: String] == ["publishable_key": "pk_test_a", "user_id": "u1"])
      #expect(SessionToken.minted(minted.data).token == "sess_9f")
      #expect(minted.data.user_id == "u1")
    }

    @Test("the core refuses a secret key for an operation of the unit it does not authenticate")
    func secretKeyRefused() async throws {
      let recorder = Recorder(body: #"{"data": []}"#)
      let mountaya = try Mountaya(credential: .secret(key: "sk_test_a"), exchange: recorder)

      let error = await #expect(throws: MountayaError.self) {
        _ = try await mountaya.admin.members.getOrganizationMembers(organization_id: "org")
      }

      #expect(error?.name == "ConfigurationError")
      #expect(await recorder.sent.isEmpty, "a refused call sends nothing")
    }
  #endif

  @Test("an admin tool's member reads its organization under its key and session token")
  func memberRead() async throws {
    let recorder = Recorder(
      body: #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 50, "#
        + #""next_cursor": null}}}}"#)
    let mountaya = try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"),
      retry: try RetryPolicy(maxRetries: 0), exchange: recorder)

    let members = try await mountaya.admin.members.getOrganizationMembers(organization_id: "o/1")

    let sent = try #require(await recorder.sent.first)
    #expect(sent.method == "GET")
    #expect(sent.url.absoluteString.hasSuffix("/v1/organizations/o%2F1/members"))
    #expect(sent.header("X-API-Key") == "pk_test_a")
    #expect(sent.header("X-Session-Token") == "sess_a")
    #expect(members.data.isEmpty)
    #expect(members.metadata.pagination.next_cursor == nil)
  }
}
