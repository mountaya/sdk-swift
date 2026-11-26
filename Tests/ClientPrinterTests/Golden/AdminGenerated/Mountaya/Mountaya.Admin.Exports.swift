// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Exports is every operation of `admin.exports`, one method to an operation.
  public struct Exports: Sendable {
    let sender: any OperationSending

    /// The contract's `getThingExport`.
    public func getThingExport(
      kind: RestSchema.ThingKind,
      thing_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> BinaryResponse {
      let request = OperationRequest(
        facts: .getThingExport,
        pathParameters: ["kind": kind.rawValue, "thing_id": thing_id]
      )
      return try await sender.binary(request, options: options)
    }

    /// The contract's `postThingUpload`.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postThingUpload(
      body: AdminSchema.PostThingUploadBody,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, RestSchema.ListMeta?> {
      let request = OperationRequest(
        facts: .postThingUpload,
        body: body.payload,
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// The contract's `deleteThing`.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteThing(
      thing_id: String,
      body: RestSchema.ThingCreate? = nil,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteThing,
        pathParameters: ["thing_id": thing_id],
        body: body.map { OperationBody.json($0) } ?? .none,
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
