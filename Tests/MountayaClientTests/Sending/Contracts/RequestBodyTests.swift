import Foundation
import Testing

@testable import MountayaClient

/// A call made by its declaration sends whatever body its operation takes, written as a printed
/// method writes it, through the whole transport.
@Suite("RequestBody")
struct RequestBodyTests {
  /// Recorder answers every attempt with an empty success and keeps what each sent.
  private actor Recorder: HTTPExchange {
    private(set) var sent: [ExchangeRequest] = []

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request)
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(#"{"data": null}"#.utf8)))
    }
  }

  private static let upload = OperationDeclaration(
    operationId: "postThingUpload", method: "POST", declaresIdempotencyKey: true)

  private static func client(_ recorder: Recorder) throws -> Mountaya {
    try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"),
      retry: try RetryPolicy(maxRetries: 0), exchange: recorder)
  }

  @Test("a form is sent as multipart/form-data, its parts in order, a file's name and type stated")
  func multipart() async throws {
    let recorder = Recorder()
    let _: Response<JSONValue, [String: JSONValue]?> = try await Self.client(recorder).send(
      Self.upload, path: "/v1/things/th/upload",
      body: .multipart([
        MultipartPart(name: "provider", content: .text("gpx")),
        MultipartPart(
          name: "file",
          content: .file(Data("<gpx/>".utf8), filename: "tour.gpx", contentType: "text/xml")),
      ]))

    let sent = try #require(await recorder.sent.first)
    let body = String(decoding: try #require(sent.body), as: UTF8.self)
    #expect(sent.header("Content-Type") == "multipart/form-data; boundary=\(FormBody.base)")
    #expect(
      body
        == "--\(FormBody.base)\r\nContent-Disposition: form-data; name=\"provider\"\r\n\r\ngpx\r\n"
        + "--\(FormBody.base)\r\nContent-Disposition: form-data; name=\"file\"; "
        + "filename=\"tour.gpx\"\r\nContent-Type: text/xml\r\n\r\n<gpx/>\r\n"
        + "--\(FormBody.base)--\r\n")
    #expect(sent.header("Idempotency-Key") != nil, "a write's key rides a form as it does JSON")
  }

  @Test("a value is sent as JSON, a printed type written by its own coding")
  func json() async throws {
    let recorder = Recorder()
    let client = try Self.client(recorder)
    let _: Response<JSONValue, [String: JSONValue]?> = try await client.send(
      Self.upload, path: "/v1/things",
      body: .json(RestSchema.CollectionItineraryUpdateParams(position: 2)))
    let _: Response<JSONValue, [String: JSONValue]?> = try await client.send(
      Self.upload, path: "/v1/things", body: .json(JSONValue.object(["name": .string("Tour")])))

    let sent = await recorder.sent
    #expect(sent.map { $0.header("Content-Type") } == ["application/json", "application/json"])
    #expect(
      sent.map { $0.body.map { String(decoding: $0, as: UTF8.self) } } == [
        #"{"position":2}"#, #"{"name":"Tour"}"#,
      ])
  }

  @Test("a file part's media type no header carries is refused before any request")
  func refusedPartType() async throws {
    let recorder = Recorder()

    await #expect {
      let _: Response<JSONValue, [String: JSONValue]?> = try await Self.client(recorder).send(
        Self.upload, path: "/v1/things/th/upload",
        body: .multipart([
          MultipartPart(name: "file", content: .file(Data(), contentType: "text/xml\r\nX-A: b"))
        ]))
    } throws: { error in
      guard case .configuration(let refusal) = error as? MountayaError else { return false }
      return refusal.message.contains("A part's media type holds a control character")
    }
    #expect(await recorder.sent.isEmpty)
  }

  @Test("a call with no body sends none, and names no content type")
  func none() async throws {
    let recorder = Recorder()
    let _: Response<JSONValue, [String: JSONValue]?> = try await Self.client(recorder).send(
      OperationDeclaration(operationId: "getThing", method: "GET", idempotent: true),
      path: "/v1/things/th")

    let sent = try #require(await recorder.sent.first)
    #expect(sent.body == nil)
    #expect(sent.header("Content-Type") == nil)
  }
}
