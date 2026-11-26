// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// PostThingUploadBody is the body of `postThingUpload`, which the contract takes in more than
  /// one media type: one case to a media type, in the contract's order. A media type the contract
  /// adds is a case of the build made after it, so a `switch` over it outside this module ends in
  /// `@unknown default`.
  @nonexhaustive
  public enum PostThingUploadBody: Sendable, Hashable {
    /// multipart is the body sent as `multipart/form-data`.
    case multipart(AdminSchema.PostThingUploadMultipartBody)
    /// json is the body sent as `application/json`.
    case json(RestSchema.ThingCreate)

    /// payload is the body as the request carries it.
    var payload: OperationBody {
      switch self {
      case .multipart(let value):
        .multipart(value.parts)
      case .json(let value):
        .json(value)
      }
    }
  }
}
