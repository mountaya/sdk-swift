import Foundation
import GateSupport
import MountayaClient
import Simulation

extension PublicRunners {
  /// errorsLadder answers with the class a failure raises: an answer's status and its one
  /// entry's code through `APIError`, and a request that never arrived as a `ConnectionError`.
  ///
  /// A case naming a `surface` is about that surface alone, and the one the fixture names is the
  /// Data API, whose answer carrying errors under a success is an `APIError` like any other the
  /// API answered. A success raises nothing on the other surfaces, so a success case naming one
  /// is not a case this runner can answer, unless it states a `body`: then the case's answer is
  /// scripted whole, its status and that text in place of an envelope, and a call reads it, the
  /// generated `directions` on the Data API and a read by its declaration elsewhere, so the class
  /// is the one the client raises for an answer that does not decode.
  static let errorsLadder = Runner(id: "transport.errors.ladder", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let code = try input.optionalString(at: "code")
    let surface = try input.optionalString(at: "surface")
    guard [nil, "data", "rest", "tiles"].contains(surface) else {
      throw FixtureError(description: "no surface is called `\(surface ?? "")`")
    }
    if let body = try input.optionalString(at: "body") {
      return .value(
        .string(
          try await undecodable(
            status: try input.integer(at: "status"), body: body, onDataApi: surface == "data"
          ).name))
    }
    let error: MountayaError
    if let status = try input.optionalInteger(at: "status") {
      if (200...299).contains(status), surface != "data" {
        throw FixtureError(description: "a success raises an error on the Data API alone")
      }
      let errors = code.map { [ErrorEntry(message: "", code: APIErrorCode(rawValue: $0))] } ?? []
      error = .api(APIError(status: status, errors: errors))
    } else {
      error = .connection(ConnectionError())
    }
    return .value(.string(error.name))
  }

  /// undecodable answers a call with `status` and `body` in place of an envelope, and returns the
  /// error the client raises reading it.
  private static func undecodable(status: Int, body: String, onDataApi: Bool) async throws
    -> MountayaError
  {
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await Simulation.run { simulation -> MountayaError in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [
          .answer(
            status: status, headers: ["X-Request-Id": "4bf92f3577b34da6a3ce929d0e0e4736"],
            body: Data(body.utf8))
        ]
      )
      do {
        if onDataApi {
          let client = try Scripted.client(
            simulation,
            exchange: exchange,
            credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc"),
            retry: noRetries
          )
          _ = try await client.data.directions(
            input: DataSchema.DirectionsInput(activity: "hiking", waypoints: [[6.86, 45.83]])
          )
        } else {
          let client = try Scripted.client(simulation, exchange: exchange, retry: noRetries)
          let _: Response<JSONValue, JSONValue?> = try await client.send(aRead, path: "/v1/things")
        }
      } catch let error as MountayaError {
        guard case .api(let answered) = error else { return error }
        // The answer came, so the error is the API's, carrying its status, its request id and the
        // decoder's failure.
        guard answered.status == status,
          answered.requestId == "4bf92f3577b34da6a3ce929d0e0e4736",
          answered.cause != nil
        else {
          throw FixtureError(
            description: "the error carries no status, request id or cause of the answer")
        }
        return error
      }
      throw FixtureError(description: "an answer that does not decode raised nothing")
    }
  }
}
