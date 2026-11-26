import Foundation
import Testing

@testable import MountayaAdmin
@testable import MountayaClient

/// The admin unit's printed methods, called through a scripted seam: each hands the core's seam
/// the contract's operation, filled in by the call, as the core's printed methods do.
@Suite("Generated admin operations")
struct GeneratedOperationsTests {
  @Test(
    "the mint sends its body to the one operation a secret key authenticates, answered as the core's session"
  )
  func mint() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": {"expires_at": "2026-03-14T10:26:53+01:00", "token": "sess_x", "user_id": "u1"}}"#
    ])
    let minted = try await sender.client.admin.sessions.postSession(
      body: .init(publishable_key: "pk_test_a") {
        $0.user_id = "u1"
        $0.surface = .api
      })

    let sent = try #require(await sender.sent.first)
    #expect(sent.request.facts == .postSession)
    #expect(sent.request.facts.credentials.requiresSecretKey)
    #expect(sent.request.path == "/v1/sessions")
    #expect(sent.json == #"{"publishable_key":"pk_test_a","surface":"api","user_id":"u1"}"#)
    // The answer is the core's session, which an app's session engine reads as it arrives.
    let session: RestSchema.Session = minted.data
    #expect(session.token == "sess_x")
    #expect(session.user_id == "u1")
    #expect(SessionToken.minted(session).token == "sess_x")
  }

  @Test(
    "a printed walk pages its listing at the operation's page size, each row as the listing types it"
  )
  func walk() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": [{"id": "pm_1", "type": "card", "is_default": true}], "#
        + #""extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": "c2"}}}}"#,
      #"{"data": [{"id": "pm_2", "type": "sepa_debit", "is_default": false}], "#
        + #""extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": null}}}}"#,
    ])
    var rows: [AdminSchema.PaymentMethod] = []
    let walk = try sender.client.admin.billing.walkGetOrganizationBillingPaymentMethods(
      organization_id: "or/1", query: .init { $0.cursor = "c1" },
      options: RequestOptions(retry: try RetryPolicy(maxRetries: 0)))
    for try await row in walk {
      rows.append(row)
    }

    let sent = await sender.sent
    #expect(rows.map(\.id) == ["pm_1", "pm_2"])
    #expect(rows.map(\.is_default) == [true, false])
    #expect(
      sent.map(\.request.facts) == [
        .getOrganizationBillingPaymentMethods, .getOrganizationBillingPaymentMethods,
      ])
    #expect(
      sent.map(\.request.path)
        == Array(repeating: "/v1/organizations/or%2F1/billing/payment-methods", count: 2))
    #expect(
      sent.map(\.request.query)
        == [
          [QueryItem(name: "cursor", value: "c1"), QueryItem(name: "limit", value: "50")],
          [QueryItem(name: "cursor", value: "c2"), QueryItem(name: "limit", value: "50")],
        ])
    #expect(sent.allSatisfy { $0.options.retry?.maxRetries == 0 })
  }

  @Test("a listing's metadata is the core's type, read as the admin unit's method declares it")
  func coreMetadata() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 2, "next_cursor": "c9"}}}}"#
    ])
    let members = try await sender.client.admin.members.getOrganizationMembers(
      organization_id: "org", query: .init { $0.limit = 2 })

    let metadata: RestSchema.ListMetadata = members.metadata
    #expect(metadata.pagination.next_cursor == "c9")
    #expect(members.data.isEmpty)
    #expect(await sender.sent.map(\.request.facts) == [.getOrganizationMembers])
  }

  @Test(
    "the admin unit's table holds its own operations and none of the core's, each the contract's")
  func facts() {
    let names = OperationFacts.adminOperations.map(\.operationId)

    #expect(Set(names).count == names.count)
    #expect(names.contains("postSession") && names.contains("getOrganizationMembers"))
    #expect(Set(names).isDisjoint(with: OperationFacts.restOperations.map(\.operationId)))
    #expect(OperationFacts.adminOperations.allSatisfy { $0.surface == .rest })
    // The one operation a secret key authenticates. The one that takes no credential at all, an
    // organization's lookup, is the core's, which a map reads its organization through.
    #expect(
      OperationFacts.adminOperations.filter(\.credentials.requiresSecretKey).map(\.operationId)
        == ["postSession"])
    #expect(OperationFacts.adminOperations.allSatisfy { !$0.credentials.takesNoCredential })
  }
}
