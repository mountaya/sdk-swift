// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension OperationFacts {
  /// dataEndpoint is the path every Data API operation is sent to, under the Data API's origin, a
  /// call made by its declaration among them.
  static let dataEndpoint = "/graphql"

  /// dataOperations is every operation of this surface, in the model's order.
  static let dataOperations: [OperationFacts] = [
    .analyzeGeometry,
    .directions,
    .exportItinerary,
    .geocode,
    .isochrones,
    .itinerary,
    .matrix,
    .pois,
    .reverseGeocode,
    .search,
    .suggestions,
    .terrainGrid,
    .terrainProfile,
    .terrainSamples,
  ]

  static let analyzeGeometry = OperationFacts(
    surface: .data,
    operationId: "analyzeGeometry",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let directions = OperationFacts(
    surface: .data,
    operationId: "directions",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let exportItinerary = OperationFacts(
    surface: .data,
    operationId: "exportItinerary",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let geocode = OperationFacts(
    surface: .data,
    operationId: "geocode",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let isochrones = OperationFacts(
    surface: .data,
    operationId: "isochrones",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let itinerary = OperationFacts(
    surface: .data,
    operationId: "itinerary",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let matrix = OperationFacts(
    surface: .data,
    operationId: "matrix",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let pois = OperationFacts(
    surface: .data,
    operationId: "pois",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let reverseGeocode = OperationFacts(
    surface: .data,
    operationId: "reverseGeocode",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let search = OperationFacts(
    surface: .data,
    operationId: "search",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let suggestions = OperationFacts(
    surface: .data,
    operationId: "suggestions",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let terrainGrid = OperationFacts(
    surface: .data,
    operationId: "terrainGrid",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let terrainProfile = OperationFacts(
    surface: .data,
    operationId: "terrainProfile",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )

  static let terrainSamples = OperationFacts(
    surface: .data,
    operationId: "terrainSamples",
    method: "POST",
    path: "/graphql",
    idempotent: true,
    credentials: CredentialDeclaration(requiresSession: true, isRead: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .result,
    successResponses: [SuccessResponse(status: 200, headers: [])],
    errorStatuses: [],
    tasks: []
  )
}
