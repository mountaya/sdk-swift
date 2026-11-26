// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension OperationFacts {
  /// restOperations is every operation of this surface but the admin unit's, which `MountayaAdmin`
  /// prints as `adminOperations`, in the model's order.
  static let restOperations: [OperationFacts] = [
    .deleteCollection,
    .deleteCollectionItinerary,
    .deleteCollectionShareLink,
    .deleteCollectionZone,
    .deleteItinerary,
    .deleteItineraryPublication,
    .deleteItinerarySegment,
    .deleteItinerarySegmentGroup,
    .deleteItineraryShareLink,
    .deleteItineraryWaypoint,
    .deleteZone,
    .deleteZonePublication,
    .getActivities,
    .getAgentRunEvents,
    .getCollection,
    .getCollectionItineraries,
    .getCollectionShareLink,
    .getCollectionZones,
    .getCollections,
    .getItineraries,
    .getItinerary,
    .getItineraryEvents,
    .getItineraryExport,
    .getItineraryPace,
    .getItineraryShareLink,
    .getLayers,
    .getOrganizationEvents,
    .getZone,
    .getZoneEvents,
    .getZones,
    .patchCollection,
    .patchCollectionItinerary,
    .patchItinerary,
    .patchItinerarySegment,
    .patchItinerarySegmentGroup,
    .patchItineraryWaypoint,
    .patchZone,
    .postAgentRun,
    .postAgentRunFeedback,
    .postAgentRunInput,
    .postCollection,
    .postCollectionItineraries,
    .postCollectionShareLink,
    .postCollectionShareLinkRotate,
    .postCollectionZones,
    .postItinerary,
    .postItineraryCollab,
    .postItineraryDuplicate,
    .postItineraryImport,
    .postItineraryPreview,
    .postItineraryPublication,
    .postItinerarySegment,
    .postItinerarySegmentConvert,
    .postItinerarySegmentGroup,
    .postItinerarySegmentMerge,
    .postItinerarySegmentSplit,
    .postItineraryShareLink,
    .postItineraryShareLinkRotate,
    .postItineraryWaypoint,
    .postOrganizationLookup,
    .postZone,
    .postZoneCollab,
    .postZonePublication,
  ]

  static let deleteCollection = OperationFacts(
    surface: .rest,
    operationId: "deleteCollection",
    method: "DELETE",
    path: "/v1/collections/{collection_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["collection.delete"]
  )

  static let deleteCollectionItinerary = OperationFacts(
    surface: .rest,
    operationId: "deleteCollectionItinerary",
    method: "DELETE",
    path: "/v1/collections/{collection_id}/itineraries/{itinerary_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["collection.itinerary.remove"]
  )

  static let deleteCollectionShareLink = OperationFacts(
    surface: .rest,
    operationId: "deleteCollectionShareLink",
    method: "DELETE",
    path: "/v1/collections/{collection_id}/share-link",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["collection.share_link.delete"]
  )

  static let deleteCollectionZone = OperationFacts(
    surface: .rest,
    operationId: "deleteCollectionZone",
    method: "DELETE",
    path: "/v1/collections/{collection_id}/zones/{zone_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["collection.zone.remove"]
  )

  static let deleteItinerary = OperationFacts(
    surface: .rest,
    operationId: "deleteItinerary",
    method: "DELETE",
    path: "/v1/itineraries/{itinerary_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.delete"]
  )

  static let deleteItineraryPublication = OperationFacts(
    surface: .rest,
    operationId: "deleteItineraryPublication",
    method: "DELETE",
    path: "/v1/itineraries/{itinerary_id}/publication",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.unpublish"]
  )

  static let deleteItinerarySegment = OperationFacts(
    surface: .rest,
    operationId: "deleteItinerarySegment",
    method: "DELETE",
    path: "/v1/itineraries/{itinerary_id}/segments/{segment_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.segment.delete"]
  )

  static let deleteItinerarySegmentGroup = OperationFacts(
    surface: .rest,
    operationId: "deleteItinerarySegmentGroup",
    method: "DELETE",
    path: "/v1/itineraries/{itinerary_id}/segment-groups/{group_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.segment_group.delete"]
  )

  static let deleteItineraryShareLink = OperationFacts(
    surface: .rest,
    operationId: "deleteItineraryShareLink",
    method: "DELETE",
    path: "/v1/itineraries/{itinerary_id}/share-link",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["itinerary.share_link.delete"]
  )

  static let deleteItineraryWaypoint = OperationFacts(
    surface: .rest,
    operationId: "deleteItineraryWaypoint",
    method: "DELETE",
    path: "/v1/itineraries/{itinerary_id}/waypoints/{waypoint_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.waypoint.delete"]
  )

  static let deleteZone = OperationFacts(
    surface: .rest,
    operationId: "deleteZone",
    method: "DELETE",
    path: "/v1/zones/{zone_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["zone.delete"]
  )

  static let deleteZonePublication = OperationFacts(
    surface: .rest,
    operationId: "deleteZonePublication",
    method: "DELETE",
    path: "/v1/zones/{zone_id}/publication",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["zone.unpublish"]
  )

  static let getActivities = OperationFacts(
    surface: .rest,
    operationId: "getActivities",
    method: "GET",
    path: "/v1/activities",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 429, 500, 504],
    tasks: []
  )

  static let getAgentRunEvents = OperationFacts(
    surface: .rest,
    operationId: "getAgentRunEvents",
    method: "GET",
    path: "/v1/agent/runs/{run_id}/events",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: nil,
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .eventStream,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 503],
    tasks: []
  )

  static let getCollection = OperationFacts(
    surface: .rest,
    operationId: "getCollection",
    method: "GET",
    path: "/v1/collections/{collection_id}",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getCollectionItineraries = OperationFacts(
    surface: .rest,
    operationId: "getCollectionItineraries",
    method: "GET",
    path: "/v1/collections/{collection_id}/itineraries",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(
      sort: ["position", "-updated_at", "name", "-name"], defaultSort: "position"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getCollectionShareLink = OperationFacts(
    surface: .rest,
    operationId: "getCollectionShareLink",
    method: "GET",
    path: "/v1/collections/{collection_id}/share-link",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getCollectionZones = OperationFacts(
    surface: .rest,
    operationId: "getCollectionZones",
    method: "GET",
    path: "/v1/collections/{collection_id}/zones",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(
      sort: ["-updated_at", "updated_at", "name", "-name"], defaultSort: "-updated_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getCollections = OperationFacts(
    surface: .rest,
    operationId: "getCollections",
    method: "GET",
    path: "/v1/collections",
    idempotent: true,
    credentials: CredentialDeclaration(),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(
      sort: ["-updated_at", "updated_at", "-created_at", "created_at", "name", "-name"],
      defaultSort: "-updated_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getItineraries = OperationFacts(
    surface: .rest,
    operationId: "getItineraries",
    method: "GET",
    path: "/v1/itineraries",
    idempotent: true,
    credentials: CredentialDeclaration(),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(
      sort: ["-updated_at", "updated_at", "-created_at", "created_at", "name", "-name"],
      defaultSort: "-updated_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getItinerary = OperationFacts(
    surface: .rest,
    operationId: "getItinerary",
    method: "GET",
    path: "/v1/itineraries/{itinerary_id}",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Cache-Control", "ETag", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getItineraryEvents = OperationFacts(
    surface: .rest,
    operationId: "getItineraryEvents",
    method: "GET",
    path: "/v1/itineraries/{itinerary_id}/events",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: nil,
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .eventStream,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 503],
    tasks: []
  )

  static let getItineraryExport = OperationFacts(
    surface: .rest,
    operationId: "getItineraryExport",
    method: "GET",
    path: "/v1/itineraries/{itinerary_id}/export",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .binary,
    successResponses: [
      SuccessResponse(
        status: 200,
        headers: ["Content-Disposition", "Content-Length", "Referrer-Policy", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 413, 429, 500, 504],
    tasks: []
  )

  static let getItineraryPace = OperationFacts(
    surface: .rest,
    operationId: "getItineraryPace",
    method: "GET",
    path: "/v1/itineraries/{itinerary_id}/pace",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["Cache-Control", "X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getItineraryShareLink = OperationFacts(
    surface: .rest,
    operationId: "getItineraryShareLink",
    method: "GET",
    path: "/v1/itineraries/{itinerary_id}/share-link",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getLayers = OperationFacts(
    surface: .rest,
    operationId: "getLayers",
    method: "GET",
    path: "/v1/layers",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["Cache-Control", "X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getOrganizationEvents = OperationFacts(
    surface: .rest,
    operationId: "getOrganizationEvents",
    method: "GET",
    path: "/v1/organizations/{organization_id}/events",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: nil,
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .eventStream,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 503],
    tasks: []
  )

  static let getZone = OperationFacts(
    surface: .rest,
    operationId: "getZone",
    method: "GET",
    path: "/v1/zones/{zone_id}",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Cache-Control", "ETag", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let getZoneEvents = OperationFacts(
    surface: .rest,
    operationId: "getZoneEvents",
    method: "GET",
    path: "/v1/zones/{zone_id}/events",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: nil,
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .eventStream,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 503],
    tasks: []
  )

  static let getZones = OperationFacts(
    surface: .rest,
    operationId: "getZones",
    method: "GET",
    path: "/v1/zones",
    idempotent: true,
    credentials: CredentialDeclaration(),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(
      sort: ["-updated_at", "updated_at", "-created_at", "created_at", "name", "-name"],
      defaultSort: "-updated_at"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 429, 500, 504],
    tasks: []
  )

  static let patchCollection = OperationFacts(
    surface: .rest,
    operationId: "patchCollection",
    method: "PATCH",
    path: "/v1/collections/{collection_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["collection.update"]
  )

  static let patchCollectionItinerary = OperationFacts(
    surface: .rest,
    operationId: "patchCollectionItinerary",
    method: "PATCH",
    path: "/v1/collections/{collection_id}/itineraries/{itinerary_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["collection.itinerary.move"]
  )

  static let patchItinerary = OperationFacts(
    surface: .rest,
    operationId: "patchItinerary",
    method: "PATCH",
    path: "/v1/itineraries/{itinerary_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.update"]
  )

  static let patchItinerarySegment = OperationFacts(
    surface: .rest,
    operationId: "patchItinerarySegment",
    method: "PATCH",
    path: "/v1/itineraries/{itinerary_id}/segments/{segment_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.segment.update"]
  )

  static let patchItinerarySegmentGroup = OperationFacts(
    surface: .rest,
    operationId: "patchItinerarySegmentGroup",
    method: "PATCH",
    path: "/v1/itineraries/{itinerary_id}/segment-groups/{group_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.segment_group.update"]
  )

  static let patchItineraryWaypoint = OperationFacts(
    surface: .rest,
    operationId: "patchItineraryWaypoint",
    method: "PATCH",
    path: "/v1/itineraries/{itinerary_id}/waypoints/{waypoint_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.waypoint.update"]
  )

  static let patchZone = OperationFacts(
    surface: .rest,
    operationId: "patchZone",
    method: "PATCH",
    path: "/v1/zones/{zone_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 503, 504],
    tasks: ["zone.update"]
  )

  static let postAgentRun = OperationFacts(
    surface: .rest,
    operationId: "postAgentRun",
    method: "POST",
    path: "/v1/agent/runs",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 202, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["agent.run.start"]
  )

  static let postAgentRunFeedback = OperationFacts(
    surface: .rest,
    operationId: "postAgentRunFeedback",
    method: "POST",
    path: "/v1/agent/runs/{run_id}/feedback",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 202, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 503, 504],
    tasks: ["agent.run.feedback.send"]
  )

  static let postAgentRunInput = OperationFacts(
    surface: .rest,
    operationId: "postAgentRunInput",
    method: "POST",
    path: "/v1/agent/runs/{run_id}/input",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 202, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["agent.run.input.send"]
  )

  static let postCollection = OperationFacts(
    surface: .rest,
    operationId: "postCollection",
    method: "POST",
    path: "/v1/collections",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["collection.create"]
  )

  static let postCollectionItineraries = OperationFacts(
    surface: .rest,
    operationId: "postCollectionItineraries",
    method: "POST",
    path: "/v1/collections/{collection_id}/itineraries",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["collection.itinerary.add"]
  )

  static let postCollectionShareLink = OperationFacts(
    surface: .rest,
    operationId: "postCollectionShareLink",
    method: "POST",
    path: "/v1/collections/{collection_id}/share-link",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"]),
      SuccessResponse(status: 201, headers: ["Idempotent-Replayed", "Location", "X-Request-Id"]),
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["collection.share_link.create"]
  )

  static let postCollectionShareLinkRotate = OperationFacts(
    surface: .rest,
    operationId: "postCollectionShareLinkRotate",
    method: "POST",
    path: "/v1/collections/{collection_id}/share-link/rotate",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["collection.share_link.rotate"]
  )

  static let postCollectionZones = OperationFacts(
    surface: .rest,
    operationId: "postCollectionZones",
    method: "POST",
    path: "/v1/collections/{collection_id}/zones",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["collection.zone.add"]
  )

  static let postItinerary = OperationFacts(
    surface: .rest,
    operationId: "postItinerary",
    method: "POST",
    path: "/v1/itineraries",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["itinerary.create"]
  )

  static let postItineraryCollab = OperationFacts(
    surface: .rest,
    operationId: "postItineraryCollab",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/collab",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["itinerary.collab.signal"]
  )

  static let postItineraryDuplicate = OperationFacts(
    surface: .rest,
    operationId: "postItineraryDuplicate",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/duplicate",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["itinerary.duplicate"]
  )

  static let postItineraryImport = OperationFacts(
    surface: .rest,
    operationId: "postItineraryImport",
    method: "POST",
    path: "/v1/itineraries/import",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(55000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["itinerary.import"]
  )

  static let postItineraryPreview = OperationFacts(
    surface: .rest,
    operationId: "postItineraryPreview",
    method: "POST",
    path: "/v1/itineraries/preview",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(55000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["itinerary.preview"]
  )

  static let postItineraryPublication = OperationFacts(
    surface: .rest,
    operationId: "postItineraryPublication",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/publication",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.publish"]
  )

  static let postItinerarySegment = OperationFacts(
    surface: .rest,
    operationId: "postItinerarySegment",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/segments",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.segment.create", "itinerary.segment.insert"]
  )

  static let postItinerarySegmentConvert = OperationFacts(
    surface: .rest,
    operationId: "postItinerarySegmentConvert",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/segments/{segment_id}/convert",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.segment.convert"]
  )

  static let postItinerarySegmentGroup = OperationFacts(
    surface: .rest,
    operationId: "postItinerarySegmentGroup",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/segment-groups",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.segment_group.create"]
  )

  static let postItinerarySegmentMerge = OperationFacts(
    surface: .rest,
    operationId: "postItinerarySegmentMerge",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/segments/{segment_id}/merge",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["itinerary.segment.merge"]
  )

  static let postItinerarySegmentSplit = OperationFacts(
    surface: .rest,
    operationId: "postItinerarySegmentSplit",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/segments/{segment_id}/split",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.segment.split"]
  )

  static let postItineraryShareLink = OperationFacts(
    surface: .rest,
    operationId: "postItineraryShareLink",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/share-link",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"]),
      SuccessResponse(status: 201, headers: ["Idempotent-Replayed", "Location", "X-Request-Id"]),
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["itinerary.share_link.create"]
  )

  static let postItineraryShareLinkRotate = OperationFacts(
    surface: .rest,
    operationId: "postItineraryShareLinkRotate",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/share-link/rotate",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 429, 500, 504],
    tasks: ["itinerary.share_link.rotate"]
  )

  static let postItineraryWaypoint = OperationFacts(
    surface: .rest,
    operationId: "postItineraryWaypoint",
    method: "POST",
    path: "/v1/itineraries/{itinerary_id}/waypoints",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 413, 429, 500, 504],
    tasks: ["itinerary.waypoint.create"]
  )

  static let postOrganizationLookup = OperationFacts(
    surface: .rest,
    operationId: "postOrganizationLookup",
    method: "POST",
    path: "/v1/organizations/lookup",
    idempotent: true,
    credentials: CredentialDeclaration(takesNoCredential: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["ETag", "X-Request-Id"])],
    errorStatuses: [400, 404, 413, 429, 500, 504],
    tasks: []
  )

  static let postZone = OperationFacts(
    surface: .rest,
    operationId: "postZone",
    method: "POST",
    path: "/v1/zones",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(
        status: 201, headers: ["ETag", "Idempotent-Replayed", "Location", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 503, 504],
    tasks: ["zone.create"]
  )

  static let postZoneCollab = OperationFacts(
    surface: .rest,
    operationId: "postZoneCollab",
    method: "POST",
    path: "/v1/zones/{zone_id}/collab",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400, 401, 402, 403, 404, 409, 413, 429, 500, 504],
    tasks: ["zone.collab.signal"]
  )

  static let postZonePublication = OperationFacts(
    surface: .rest,
    operationId: "postZonePublication",
    method: "POST",
    path: "/v1/zones/{zone_id}/publication",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 200, headers: ["ETag", "Idempotent-Replayed", "X-Request-Id"])
    ],
    errorStatuses: [400, 401, 402, 403, 404, 409, 412, 429, 500, 504],
    tasks: ["zone.publish"]
  )
}
