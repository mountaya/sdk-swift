// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension OperationFacts {
  /// adminOperations is every operation of the admin unit, in the model's order.
  static let adminOperations: [OperationFacts] = [
    .getThingExport,
    .postThingUpload,
    .deleteThing,
  ]

  static let getThingExport = OperationFacts(
    surface: .rest,
    operationId: "getThingExport",
    method: "GET",
    path: "/v1/kinds/{kind}/things/{thing_id}/export",
    idempotent: true,
    credentials: CredentialDeclaration(takesNoCredential: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .binary,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [],
    tasks: []
  )

  static let postThingUpload = OperationFacts(
    surface: .rest,
    operationId: "postThingUpload",
    method: "POST",
    path: "/v1/things/uploads/multipart/in-a-path-long-enough-that-its-literal-is-broken"
      + "/across-two-lines/confirm",
    idempotent: false,
    credentials: CredentialDeclaration(requiresSecretKey: true),
    timeout: .milliseconds(55000),
    declaresIdempotencyKey: true,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 202, headers: ["X-Request-Id"])],
    errorStatuses: [],
    tasks: ["thing.upload.confirm", "thing.upload.import"]
  )

  static let deleteThing = OperationFacts(
    surface: .rest,
    operationId: "deleteThing",
    method: "DELETE",
    path: "/v1/things/{thing_id}",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: true,
    isConditional: true,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [404, 500],
    tasks: ["thing.delete"]
  )
}
