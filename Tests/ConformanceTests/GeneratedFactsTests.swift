import Foundation
import GateSupport
import Testing

@testable import MountayaAdmin
@testable import MountayaClient

/// The printed facts tables against the model, operation by operation, each unit's against the
/// operations the model gives that unit.
///
/// A printer that dropped `x-idempotent` would ship a client that repeats a write after a
/// dropped socket, and nothing else would fail; a printer that dropped a credential fact would
/// send a request the server refuses; one that dropped `idempotencyKey` would send a write with
/// no key. Every fact the transport reads is compared, the headers each success declares among
/// them, then the tasks each write triggers, which the transport does not read, and the count.
/// The model is held to the bundles byte for byte by the contract's own gate, so this reads the
/// model.
@Suite("Generated facts")
struct GeneratedFactsTests {
  private static func model() throws -> (OrderedJSON, URL)? {
    guard let checkout = try Conformance.contract.get()?.checkout else { return nil }
    let url = checkout.directory.appendingPathComponent("sdk/model.json")
    let text = try #require(SourceTree.read(url), "sdk/model.json cannot be read")
    return (try OrderedJSON.parse(text), checkout.directory)
  }

  @Test(
    "every printed REST and Tile operation declares what the model says, and no other is printed",
    arguments: [("rest", "core"), ("rest", "admin"), ("tiles", "core")]
  )
  func openApiSurfaces(surface: String, unit: String) throws {
    guard let (model, _) = try Self.model() else { return }
    let printed =
      surface == "tiles"
      ? OperationFacts.tileOperations
      : unit == "admin" ? OperationFacts.adminOperations : OperationFacts.restOperations
    // Each unit prints the table of the operations the model gives it, and no other.
    let operations = try #require(model[surface]?["operations"]?.elements).filter {
      $0["unit"]?.stringValue == unit
    }
    try #require(!operations.isEmpty, "the model gives the \(unit) unit no operation of \(surface)")

    #expect(printed.count == operations.count)
    for (facts, operation) in zip(printed, operations) {
      let name = try operation.string(at: "operationId")
      let credentials = try #require(operation["credentials"])
      let success = try #require(operation["success"])
      let errors = try #require(operation["errors"]?.elements)
      let actingUser = try #require(
        CredentialDeclaration.ActingUser(rawValue: try credentials.string(at: "actingUser")),
        "\(name)"
      )

      #expect(facts.operationId == name)
      #expect(facts.surface.rawValue == surface, "\(name)")
      #expect(facts.method == (try operation.string(at: "method")), "\(name)")
      #expect(facts.path == (try operation.string(at: "path")), "\(name)")
      #expect(facts.idempotent == (try operation.flag(at: "idempotent")), "\(name)")
      #expect(
        facts.credentials
          == CredentialDeclaration(
            actingUser: actingUser,
            acceptsShareToken: try credentials.flag(at: "acceptsShareToken"),
            requiresSession: try credentials.flag(at: "requiresSession"),
            requiresSecretKey: try credentials.flag(at: "requiresSecretKey"),
            takesNoCredential: try credentials.flag(at: "takesNoCredential"),
            pendingInvitee: try credentials.flag(at: "pendingInvitee")
          ),
        "\(name)"
      )
      #expect(
        facts.timeout == (try operation.optionalInteger(at: "timeoutMs")).map { .milliseconds($0) },
        "\(name)"
      )
      #expect(
        facts.declaresIdempotencyKey == (try operation.flag(at: "idempotencyKey")), "\(name)"
      )
      #expect(facts.isConditional == (try operation.flag(at: "conditional")), "\(name)")
      #expect(facts.answersNotModified == (try operation.flag(at: "notModified")), "\(name)")
      #expect(facts.pagination == (try Self.pagination(operation["pagination"])), "\(name)")
      #expect(facts.success.rawValue == (try success.string(at: "kind")), "\(name)")
      #expect(
        facts.successResponses
          == (try success.array(at: "responses").map { response in
            OperationFacts.SuccessResponse(
              status: try response.integer(at: "status"),
              headers: try response.array(at: "headers").map { try $0.string(at: "name") }
            )
          }),
        "\(name)"
      )
      #expect(
        facts.errorStatuses == (try errors.map { try $0.integer(at: "status") }.sorted()),
        "\(name)"
      )
      #expect(
        facts.tasks
          == (try (operation["tasks"]?.elements ?? []).map { try #require($0.stringValue) }),
        "\(name)"
      )
    }
  }

  /// pagination reads an operation's `pagination`, or nil where it pages by no cursor.
  private static func pagination(_ json: OrderedJSON?) throws -> OperationFacts.Pagination? {
    guard let json, !json.isNull else { return nil }
    return OperationFacts.Pagination(
      sort: try json.array(at: "sort").map { try #require($0.stringValue) },
      defaultSort: try json.optionalString(at: "defaultSort")
    )
  }

  @Test(
    "every printed Data API operation declares what the model says, and prints its full document")
  func dataApi() throws {
    guard let (model, _) = try Self.model() else { return }
    let data = try #require(model["data"])
    let operations = try #require(data["operations"]?.elements)
    let endpoint = try data.string(at: "endpoint")

    #expect(OperationFacts.dataOperations.count == operations.count)
    for (facts, operation) in zip(OperationFacts.dataOperations, operations) {
      let name = try operation.string(at: "name")
      let credentials = try #require(operation["credentials"], "\(name) declares no credentials")
      let success = try #require(operation["success"], "\(name) declares no success")
      let actingUser = try #require(
        CredentialDeclaration.ActingUser(rawValue: try credentials.string(at: "actingUser")),
        "\(name)"
      )

      #expect(facts.operationId == name)
      #expect(facts.surface == .data)
      #expect(facts.method == "POST")
      #expect(facts.path == endpoint)
      #expect(facts.idempotent, "\(name)")
      #expect(
        facts.credentials
          == CredentialDeclaration(
            actingUser: actingUser,
            acceptsShareToken: try credentials.flag(at: "acceptsShareToken"),
            requiresSession: try credentials.flag(at: "requiresSession"),
            requiresSecretKey: try credentials.flag(at: "requiresSecretKey"),
            takesNoCredential: try credentials.flag(at: "takesNoCredential"),
            pendingInvitee: try credentials.flag(at: "pendingInvitee"),
            // A query is a read whatever method it travels over (`sdk/SPEC.md` §1).
            isRead: try operation.string(at: "document").hasPrefix("query ")
          ),
        "\(name)"
      )
      #expect(facts.timeout == .milliseconds(try operation.integer(at: "timeoutMs")), "\(name)")
      #expect(!facts.declaresIdempotencyKey, "\(name)")
      #expect(!facts.isConditional, "\(name)")
      #expect(facts.pagination == nil, "\(name)")
      #expect(facts.success == .result, "\(name)")
      #expect(
        facts.successResponses
          == (try success.array(at: "responses").map { response in
            OperationFacts.SuccessResponse(
              status: try response.integer(at: "status"),
              headers: try response.array(at: "headers").map { try $0.string(at: "name") }
            )
          }),
        "\(name)"
      )
      #expect(facts.errorStatuses.isEmpty, "\(name)")
      #expect(facts.tasks.isEmpty, "\(name)")
    }

    let trees = [
      DataOperation.analyzeGeometry, .directions, .exportItinerary, .geocode, .isochrones,
      .itinerary, .matrix, .pois, .reverseGeocode, .search, .suggestions, .terrainGrid,
      .terrainProfile, .terrainSamples,
    ]
    #expect(trees.count == operations.count)
    #expect(OperationFacts.dataEndpoint == endpoint)
    for operation in operations {
      let name = try operation.string(at: "name")
      let printed = try #require(trees.first { $0.name == name }, "\(name) is not printed")
      #expect(printed.document == (try operation.string(at: "document")), "\(name)")
      #expect(printed.timeout == .milliseconds(try operation.integer(at: "timeoutMs")), "\(name)")
    }
  }

  @Test(
    "every route a renderer fetches is printed as the model's template, and no other is printed",
    arguments: ["rest", "tiles"]
  )
  func templates(surface: String) throws {
    guard let (model, _) = try Self.model() else { return }
    let templates = try #require(model[surface]?["templates"]?.elements)
    // REST declares no template at this tag, and prints no namespace of its own for none.
    let printed = surface == "tiles" ? TileTemplates.all : []

    #expect(printed.count == templates.count)
    for (template, route) in zip(printed, templates) {
      let path = try route.string(at: "path")
      let parameters = try route.array(at: "pathParameters").map { try $0.string(at: "name") }
      let placed = try parameters.sorted { first, second in
        let one = try #require(path.range(of: "{\(first)}"), "\(first) is not in \(path)")
        let other = try #require(path.range(of: "{\(second)}"), "\(second) is not in \(path)")
        return one.lowerBound < other.lowerBound
      }

      #expect(template.operationId == (try route.string(at: "operationId")))
      #expect(template.path == path, "\(template.operationId)")
      #expect(template.pathParameters == placed, "\(template.operationId)")
      #expect(
        template.queryParameters
          == (try route.array(at: "queryParameters").map { try $0.string(at: "name") }),
        "\(template.operationId)")
      #expect(
        template.mediaTypes
          == (try #require(route["success"]).array(at: "mediaTypes").map {
            try #require($0.stringValue)
          }),
        "\(template.operationId)")
    }
  }

  @Test("the schema version is the model's contract and the checkout's VERSION")
  func printedTag() throws {
    guard let (model, directory) = try Self.model() else { return }
    let version = try #require(
      SourceTree.read(directory.appendingPathComponent("VERSION")),
      "VERSION cannot be read"
    )

    #expect(schemaVersion == (try model.string(at: "contract")))
    #expect(schemaVersion == version.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  @Test("the model digest is the digest of the checkout's model and elements' data")
  func printedDigest() throws {
    guard let (_, directory) = try Self.model() else { return }

    #expect(modelDigest == (try ModelDigest.digest(ofCheckout: directory)))
  }
}
