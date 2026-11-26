// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension OperationFacts {
  /// tileOperations is every operation of this surface, in the model's order.
  static let tileOperations: [OperationFacts] = [
    .getCollectionSpecification,
    .getItinerariesSpecification,
    .getItinerarySpecification,
    .getOverlaySpecification,
    .getTileLayers,
    .getZonesSpecification,
  ]

  static let getCollectionSpecification = OperationFacts(
    surface: .tiles,
    operationId: "getCollectionSpecification",
    method: "GET",
    path: "/v1/collections/{collection_id}/specification",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 200, headers: ["Cache-Control", "RateLimit", "RateLimit-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 405, 429, 500, 504],
    tasks: []
  )

  static let getItinerariesSpecification = OperationFacts(
    surface: .tiles,
    operationId: "getItinerariesSpecification",
    method: "GET",
    path: "/v1/itineraries/specification",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 200, headers: ["Cache-Control", "RateLimit", "RateLimit-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 405, 429, 500, 504],
    tasks: []
  )

  static let getItinerarySpecification = OperationFacts(
    surface: .tiles,
    operationId: "getItinerarySpecification",
    method: "GET",
    path: "/v1/itineraries/{itinerary_id}/specification",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 200, headers: ["Cache-Control", "RateLimit", "RateLimit-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 405, 429, 500, 504],
    tasks: []
  )

  static let getOverlaySpecification = OperationFacts(
    surface: .tiles,
    operationId: "getOverlaySpecification",
    method: "GET",
    path: "/v1/overlays/{overlay}/specification",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 200, headers: ["Cache-Control", "RateLimit", "RateLimit-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 405, 429, 500, 504],
    tasks: []
  )

  static let getTileLayers = OperationFacts(
    surface: .tiles,
    operationId: "getTileLayers",
    method: "GET",
    path: "/v1/tile-layers",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 200, headers: ["Cache-Control", "RateLimit", "RateLimit-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 405, 429, 500, 504],
    tasks: []
  )

  static let getZonesSpecification = OperationFacts(
    surface: .tiles,
    operationId: "getZonesSpecification",
    method: "GET",
    path: "/v1/zones/specification",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 200, headers: ["Cache-Control", "RateLimit", "RateLimit-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 405, 429, 500, 504],
    tasks: []
  )
}
