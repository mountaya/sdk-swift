// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension OperationFacts {
  /// tileOperations is every operation of this surface, in the model's order.
  static let tileOperations: [OperationFacts] = [
    .getSpec
  ]

  static let getSpec = OperationFacts(
    surface: .tiles,
    operationId: "getSpec",
    method: "GET",
    path: "/v1/spec",
    idempotent: true,
    credentials: CredentialDeclaration(acceptsShareToken: true),
    timeout: .milliseconds(30000),
    declaresIdempotencyKey: false,
    isConditional: false,
    answersNotModified: false,
    pagination: nil,
    success: .envelope,
    successResponses: [SuccessResponse(status: 200, headers: ["X-Request-Id"])],
    errorStatuses: [404],
    tasks: []
  )
}
