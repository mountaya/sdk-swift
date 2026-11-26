// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension OperationFacts {
  /// dataEndpoint is the path every Data API operation is sent to, under the Data API's origin, a
  /// call made by its declaration among them.
  static let dataEndpoint = "/graphql"

  /// dataOperations is every operation of this surface, in the model's order.
  static let dataOperations: [OperationFacts] = [
    .lookup
  ]

  static let lookup = OperationFacts(
    surface: .data,
    operationId: "lookup",
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
