import Testing

@testable import MountayaClient

@Suite("OperationFacts")
struct OperationFactsTests {
  @Test("an operation's facts are the contract's, never the method's")
  func readFromTheContract() {
    // A write that takes no key, and a read that acts as the user its token names. The writes a
    // credential of their own authenticates and the mint a secret key alone does are the admin
    // unit's (`MountayaAdminTests`).
    let collab = OperationFacts.restOperations.first { $0.operationId == "postItineraryCollab" }

    #expect(collab?.method == "POST")
    #expect(collab?.declaresIdempotencyKey == false)
    #expect(collab?.credentials.actingUser == .required)
    #expect(OperationFacts.getItineraryShareLink.credentials.actingUser == .required)
    #expect(OperationFacts.getAgentRunEvents.success == .eventStream)
  }

  @Test("the core's table holds its own operations, none of the admin unit's")
  func coreTable() {
    let names = Set(OperationFacts.restOperations.map(\.operationId))

    #expect(names.contains("getItinerary"))
    #expect(!names.contains("postSession"), "the mint is the admin unit's")
    #expect(
      names.contains("postOrganizationLookup"), "an organization's lookup is the core's, a map's")
    #expect(OperationFacts.restOperations.allSatisfy { !$0.credentials.requiresSecretKey })
  }

  @Test("an organization's lookup takes no credential and repeats as a read does")
  func lookupFacts() {
    #expect(OperationFacts.postOrganizationLookup.method == "POST")
    #expect(OperationFacts.postOrganizationLookup.credentials.takesNoCredential)
    #expect(!OperationFacts.postOrganizationLookup.declaresIdempotencyKey)
    #expect(
      OperationFacts.restOperations.filter(\.credentials.takesNoCredential).map(\.operationId)
        == ["postOrganizationLookup"])
  }

  @Test("a write carries its acting user, its key and its condition, a stream no budget")
  func writeFacts() {
    let delete = OperationFacts.deleteCollection

    #expect(delete.credentials.actingUser == .required)
    #expect(delete.declaresIdempotencyKey)
    #expect(delete.isConditional)
    #expect(delete.timeout == .seconds(30))
    #expect(delete.errorStatuses.contains(412))
    #expect(OperationFacts.getAgentRunEvents.timeout == nil)
  }

  @Test("a listing that pages by cursor carries its orders, and a Data API operation its budget")
  func paginationAndDataBudget() {
    #expect(OperationFacts.getCollections.pagination?.defaultSort == "-updated_at")
    #expect(OperationFacts.getCollections.pagination?.sort.contains("name") == true)
    #expect(OperationFacts.getCollection.pagination == nil)
    #expect(OperationFacts.dataOperations.allSatisfy { $0.timeout == .seconds(30) })
  }

  @Test("a Data API operation's declaration states the facts its printed method sends")
  func declaredDataFacts() {
    let trees = [
      DataOperation.analyzeGeometry, .directions, .exportItinerary, .geocode, .isochrones,
      .itinerary, .matrix, .pois, .reverseGeocode, .search, .suggestions, .terrainGrid,
      .terrainProfile, .terrainSamples,
    ]

    #expect(trees.map { OperationFacts(declaring: $0) } == OperationFacts.dataOperations)
    let bare = OperationFacts(
      declaring: DataOperation(name: "elevationAt", inputType: "ElevationInput!", selection: true))
    #expect(bare.path == OperationFacts.dataEndpoint)
    #expect(bare.surface == .data)
    #expect(bare.timeout == nil, "a declaration that states no budget takes the client's")
  }
}
