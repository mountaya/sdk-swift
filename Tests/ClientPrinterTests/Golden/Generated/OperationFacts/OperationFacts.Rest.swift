// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension OperationFacts {
  /// restOperations is every operation of this surface but the admin unit's, which `MountayaAdmin`
  /// prints as `adminOperations`, in the model's order.
  static let restOperations: [OperationFacts] = [
    .getThing,
    .listThings,
    .patchThing,
    .postThing,
    .getThingEvents,
  ]

  static let getThing = OperationFacts(
    surface: .rest,
    operationId: "getThing",
    method: "GET",
    path: "/v1/things/{thing_id}",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: true,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id", "ETag"])],
    errorStatuses: [401, 404],
    tasks: []
  )

  static let listThings = OperationFacts(
    surface: .rest,
    operationId: "listThings",
    method: "GET",
    path: "/v1/things",
    idempotent: true,
    credentials: CredentialDeclaration(
      actingUser: .optional, requiresSession: true, pendingInvitee: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: Pagination(sort: ["name", "-name"], defaultSort: "name"),
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [400],
    tasks: []
  )

  static let patchThing = OperationFacts(
    surface: .rest,
    operationId: "patchThing",
    method: "PATCH",
    path: "/v1/things/{thing_id}",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [409, 412],
    tasks: ["thing.update"]
  )

  static let postThing = OperationFacts(
    surface: .rest,
    operationId: "postThing",
    method: "POST",
    path: "/v1/things",
    idempotent: false,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(55000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [
      SuccessResponse(status: 201, headers: ["X-Request-Id", "Location"]),
      SuccessResponse(status: 200, headers: ["X-Request-Id"]),
    ],
    errorStatuses: [],
    tasks: ["thing.create"]
  )

  static let getThingEvents = OperationFacts(
    surface: .rest,
    operationId: "getThingEvents",
    method: "GET",
    path: "/v1/things/{thing_id}/events",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: nil,
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .eventStream,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [],
    tasks: []
  )
}
