import Foundation
import GateSupport
import Testing

@testable import ClientPrinter

/// The printer against a miniature model holding one of every kind, compared byte for byte
/// with the files it is meant to print.
///
/// The golden files sit in `Golden/Generated/`, the core's, and `Golden/AdminGenerated/`, the admin
/// unit's, and the gate lints them as it lints the printed tree. After a deliberate change to the
/// printer, `MOUNTAYA_GOLDEN=write swift test --filter ClientPrinterTests` rewrites them, and the
/// diff is what a reviewer reads.
@Suite("ClientPrinter")
struct ClientPrinterTests {
  private static let golden = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Golden")

  private static func miniature() throws -> String {
    try String(contentsOf: golden.appendingPathComponent("model.json"), encoding: .utf8)
  }

  /// digest is the miniatures' own digest, the golden model and elements read under the paths
  /// the contract's five inputs take, which every golden file's header names.
  static let digest: String = {
    let files = ModelDigest.inputs.map { path in
      let file = path.replacing("sdk/", with: "")
      return (path, (try? Data(contentsOf: golden.appendingPathComponent(file))) ?? Data())
    }
    return ModelDigest.digest(of: files)
  }()

  private static func files(_ text: String) throws -> [ClientUnit: [GeneratedFile]] {
    try ClientPrinter.files(for: try Model.parse(text), digest: digest)
  }

  /// file is the text a unit prints at a path, the core's unless another is named.
  private static func file(
    _ printed: [ClientUnit: [GeneratedFile]], at path: String, in unit: ClientUnit = .core
  ) throws -> String {
    try #require(printed[unit]?.first { $0.path == path }, "\(unit.module) prints no `\(path)`")
      .text
  }

  /// directory is the directory a unit's golden files sit in.
  private static func directory(of unit: ClientUnit) -> URL {
    golden.appendingPathComponent(unit == .core ? "Generated" : "AdminGenerated")
  }

  private static func refusal(_ text: String) -> String? {
    do {
      _ = try files(text)
      return nil
    } catch {
      return "\(error)"
    }
  }

  @Test(
    "the miniature model prints each unit's golden files, byte for byte",
    arguments: ClientUnit.allCases)
  func golden(unit: ClientUnit) throws {
    let printed = try Self.files(try Self.miniature())[unit] ?? []
    let directory = Self.directory(of: unit)

    if ProcessInfo.processInfo.environment["MOUNTAYA_GOLDEN"] == "write" {
      try FileTree.write(printed, replacing: FileTree.files(under: directory), at: directory)
    }

    #expect(
      FileTree.files(under: directory) == printed.map(\.path),
      "the golden files are not the files the miniature model prints"
    )
    for file in printed {
      let url = directory.appendingPathComponent(file.path)
      let expected = try String(contentsOf: url, encoding: .utf8)
      #expect(file.text == expected, "\(file.path)")
    }
  }

  @Test("printing is deterministic")
  func deterministic() throws {
    let text = try Self.miniature()

    #expect(try Self.files(text) == Self.files(text))
  }

  /// A case added to an exhaustive enum breaks every `switch` written against it, so every printed
  /// enum a later contract gives another case carries the attribute the error ladder carries.
  @Test("every union, a body taken in several media types and the webhook event are nonexhaustive")
  func nonexhaustive() throws {
    var enums: [String: Bool] = [:]
    for file in try Self.files(try Self.miniature()).values.joined() {
      var previous = ""
      for line in file.text.split(separator: "\n") {
        let text = line.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("public enum "), !text.hasSuffix("{}") {
          let name = text.dropFirst("public enum ".count).prefix { $0.isLetter || $0.isNumber }
          enums[String(name)] = previous == "@nonexhaustive"
        }
        previous = text
      }
    }

    // The templates' namespace has no case to add, so it is the one enum the attribute skips.
    #expect(
      enums == [
        "Event": true, "PostThingUploadBody": true, "ThingChoice": true, "TileTemplates": false,
        "WebhookEvent": true, "WebhookEventObject": true,
      ])
  }

  @Test("a model version the printer was not written for is refused", arguments: [1, 3])
  func refusesVersion(version: Int) throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"modelVersion\": 2",
      with: "\"modelVersion\": \(version)"
    )

    #expect(
      Self.refusal(text)?.contains("modelVersion \(version), and this printer reads 2") == true)
  }

  @Test("a kind the printer does not know is refused, never skipped")
  func refusesKinds() throws {
    let type = try Self.miniature().replacingOccurrences(
      of: "{ \"kind\": \"any\" }",
      with: "{ \"kind\": \"tuple\" }"
    )
    let schema = try Self.miniature().replacingOccurrences(
      of: "\"kind\": \"geojson\"",
      with: "\"kind\": \"feature\""
    )

    #expect(Self.refusal(type)?.contains("kind `tuple`") == true)
    #expect(Self.refusal(schema)?.contains("kind `feature`") == true)
  }

  @Test("a synthesized name a component already holds is refused, never renamed")
  func refusesCollisions() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"name\": \"ListMeta\"",
      with: "\"name\": \"GetThingQuery\""
    ).replacingOccurrences(of: "\"name\": \"ListMeta\"", with: "\"name\": \"GetThingQuery\"")
      .replacingOccurrences(
        of: "{ \"kind\": \"ref\", \"name\": \"ListMeta\" }",
        with: "{ \"kind\": \"ref\", \"name\": \"GetThingQuery\" }"
      )

    #expect(Self.refusal(text)?.contains("GetThingQuery") == true)
  }

  @Test(
    "the error code is every surface's codes once, in the order the surfaces first declare them")
  func errorCode() throws {
    let printed = try Self.file(try Self.files(try Self.miniature()), at: "APIErrorCode.swift")
    let members = printed.split(separator: "\n").compactMap { line -> String? in
      let text = line.trimmingCharacters(in: .whitespaces)
      guard text.hasPrefix("public static let ") else { return nil }
      return String(text.dropFirst("public static let ".count).prefix { $0 != ":" })
    }

    #expect(
      members == ["badRequest", "limitReached", "notFound", "tileGone", "graphqlParseFailed"])
    #expect(printed.contains("public struct APIErrorCode: RawRepresentable"))
    #expect(
      printed.contains("`LIMIT_REACHED`, as the wire spells it, which the Map Studio API declares.")
    )
    #expect(printed.contains("`TILE_GONE`, as the wire spells it, which the Tile API declares."))
  }

  @Test(
    "a surface that declares no error vocabulary is refused, never left out of the union",
    arguments: [
      ("\"enum\": [\"NOT_FOUND\", \"TILE_GONE\"]", "tiles: declares no `ErrorExtensionsCode`"),
      ("\"name\": \"ErrorCode\"", "data: declares no `ErrorCode`"),
    ])
  func refusesMissingErrorCodes(of: String, says: String) throws {
    let text = try Self.miniature().replacingOccurrences(
      of: of,
      with: of.replacingOccurrences(of: "\"enum\"", with: "\"examples\"")
        .replacingOccurrences(of: "\"ErrorCode\"", with: "\"FailureCode\""))

    #expect(Self.refusal(text)?.contains(says) == true, "\(Self.refusal(text) ?? "no refusal")")
  }

  @Test("a form's file part carries the media type its encoding names, written as a literal")
  func formEncoding() throws {
    let printed = try Self.files(try Self.miniature())
    let form = try Self.file(
      printed, at: "AdminSchema/AdminSchema.PostThingUploadMultipartBody.swift", in: .admin)

    #expect(form.contains("content: .file(self.file, contentType: \"application/gpx+xml\")"))
  }

  @Test(
    "an encoding of a part the form does not hold, or of one written as text, is refused",
    arguments: [
      ("\"property\": \"file\"", "\"property\": \"scan\"", "which the form does not hold"),
      ("\"property\": \"file\"", "\"property\": \"note\"", "the printer writes it as text"),
    ])
  func refusesEncoding(of: String, with: String, says: String) throws {
    let text = try Self.miniature().replacingOccurrences(of: of, with: with)

    #expect(Self.refusal(text)?.contains(says) == true, "\(Self.refusal(text) ?? "no refusal")")
  }

  @Test("a component named like a type the printed code uses is refused")
  func refusesShadowing() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"name\": \"Names\"",
      with: "\"name\": \"Date\""
    ).replacingOccurrences(
      of: "{ \"kind\": \"ref\", \"name\": \"Names\" }",
      with: "{ \"kind\": \"ref\", \"name\": \"Date\" }"
    )

    #expect(Self.refusal(text)?.contains("RestSchema.Date") == true)
  }

  @Test("an acting user the printer does not know is refused")
  func refusesActingUser() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"actingUser\": \"optional\"",
      with: "\"actingUser\": \"maybe\""
    )

    #expect(Self.refusal(text)?.contains("`maybe`, which this printer does not know") == true)
  }

  @Test("a description is a string, and a map where one stands is refused")
  func refusesMapDescription() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"description\": \"A small one.\"",
      with: "\"description\": { \"A small one\": \"it fits in a hand.\" }"
    )

    #expect(Self.refusal(text)?.contains("description: not a string") == true)
  }

  @Test(
    "a header the client sends itself is refused among the caller's",
    arguments: ["Last-Event-ID", "Idempotency-Key", "If-Match", "Accept-Language"]
  )
  func refusesClientHeaders(header: String) throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"name\": \"X-Trace\"",
      with: "\"name\": \"\(header)\""
    )

    #expect(Self.refusal(text)?.contains("`\(header)` among the caller's headers") == true)
  }

  @Test("a property inherited from a parent the component does not extend is refused")
  func refusesUnknownParent() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"from\": \"ListMeta\"",
      with: "\"from\": \"Thing\""
    )

    #expect(Self.refusal(text)?.contains("inherited from `Thing`") == true)
  }

  @Test("a template that is not binary is refused")
  func refusesTemplateKinds() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"mediaTypes\": [\"application/x-protobuf\"]",
      with: "\"data\": { \"type\": { \"kind\": \"any\" } }"
    ).replacingOccurrences(
      of: "\"success\": { \"kind\": \"binary\", \"data\"",
      with: "\"success\": { \"kind\": \"envelope\", \"data\""
    )

    #expect(Self.refusal(text)?.contains("a template that is not binary") == true)
  }

  @Test("a paged operation is walked beside its method, at the page size its `limit` states")
  func walks() throws {
    let printed = try Self.files(try Self.miniature())
    let things = try Self.file(printed, at: "Mountaya/Mountaya.Studio.Things.swift")

    #expect(
      things.contains(
        """
            public func walkListThings(
              query: RestSchema.ListThingsQuery,
              pageSize: Int = 20,
              maxPages: Int? = nil,
              options: RequestOptions = RequestOptions()
            ) throws(MountayaError) -> PageWalk<RestSchema.ListThingsQuery, RestSchema.Thing> {
              try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
                try await listThings(query: page, options: options)
              }
            }
        """))
    #expect(!things.contains("walkGetThing("), "an operation that pages no cursor has no walk")
  }

  @Test("a paged operation whose `limit` states no default is refused, never given one")
  func refusesWalkWithoutPageSize() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"format\": \"int32\" }, \"default\": 20 },", with: "\"format\": \"int32\" } },")

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains("its `limit` states no default") == true)
  }

  @Test("a walk named as another operation of its accessor is refused, never renamed")
  func refusesWalkCollisions() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"operationId\": \"getThing\"", with: "\"operationId\": \"walkListThings\""
    )

    #expect(text != (try Self.miniature()))
    #expect(
      Self.refusal(text)?.contains(
        "RestSchema.walkListThings: the walk listThings synthesizes is an operation's name") == true
    )
  }

  @Test("the routes a renderer fetches are URL templates, their parameters in the path's order")
  func templates() throws {
    let printed = try Self.files(try Self.miniature())
    let templates = try Self.file(printed, at: "TileTemplates.swift")

    #expect(templates.contains("public static let all: [URLTemplate] = [\n    getTile,\n"))
    #expect(
      templates.contains(
        """
            operationId: "getTile",
            path: "/v1/{z}/{x}/{y}",
            pathParameters: ["z", "x", "y"],
            queryParameters: ["timestamp"],
            mediaTypes: ["application/x-protobuf"]
        """))
    #expect(
      !printed.values.joined().contains { $0.path == "RestTemplates.swift" },
      "REST declares no template")
  }

  @Test("a template whose name no static member can take is refused", arguments: ["all", "3d"])
  func refusesTemplateNames(name: String) throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"operationId\": \"getStyle\"", with: "\"operationId\": \"\(name)\""
    )

    #expect(
      Self.refusal(text)?.contains("TileTemplates.\(name): no name a template can take") == true)
  }

  @Test("each Data API tree carries its budget, and the endpoint they are sent to is printed")
  func dataBudgets() throws {
    let printed = try Self.files(try Self.miniature())
    let trees = try Self.file(printed, at: "DataOperation.Trees.swift")
    let facts = try Self.file(printed, at: "OperationFacts/OperationFacts.Data.swift")

    #expect(trees.contains("  ],\n    timeout: .milliseconds(30000)\n  )\n"))
    #expect(facts.contains("  static let dataEndpoint = \"/graphql\"\n"))
  }

  @Test("an operation that pages by cursor and takes no cursor is refused")
  func refusesPaginationWithoutCursor() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "{ \"name\": \"cursor\", \"required\": false, \"type\": { \"kind\": \"string\" } },",
      with: ""
    )

    #expect(Self.refusal(text)?.contains("takes no `cursor`") == true)
  }

  @Test(
    "the facts a write declares are printed, each success status with its headers, and its call takes a key and a tag"
  )
  func writeFacts() throws {
    let printed = try Self.files(try Self.miniature())
    let facts = try Self.file(printed, at: "OperationFacts/OperationFacts.Rest.swift")
    let exports = try Self.file(printed, at: "Mountaya/Mountaya.Admin.Exports.swift", in: .admin)

    #expect(
      facts.contains(
        "credentials: CredentialDeclaration(actingUser: .required, requiresSession: true),"))
    #expect(facts.contains("timeout: .milliseconds(55000),"))
    #expect(facts.contains("declaresIdempotencyKey: true,\n    isConditional: true,"))
    #expect(
      facts.contains(
        """
            successResponses: [
              SuccessResponse(status: 201, headers: ["X-Request-Id", "Location"]),
              SuccessResponse(status: 200, headers: ["X-Request-Id"]),
            ],
        """))
    #expect(exports.contains("  idempotencyKey: String? = nil,\n      ifMatch: String? = nil,\n"))
    #expect(exports.contains("idempotencyKey: idempotencyKey,\n        ifMatch: ifMatch\n"))
  }

  @Test("the tasks an operation triggers are its facts, in the contract's order, none for a read")
  func taskFacts() throws {
    let printed = try Self.files(try Self.miniature())
    let facts = try Self.file(printed, at: "OperationFacts/OperationFacts.Rest.swift")
    let admin = try Self.file(printed, at: "OperationFacts/OperationFacts.Admin.swift", in: .admin)

    #expect(
      admin.contains(
        "errorStatuses: [],\n    tasks: [\"thing.upload.confirm\", \"thing.upload.import\"]\n"))
    #expect(admin.contains("errorStatuses: [404, 500],\n    tasks: [\"thing.delete\"]\n"))
    #expect(facts.contains("errorStatuses: [401, 404],\n    tasks: []\n"))
  }

  @Test("each webhook is a case of the event, carrying its object and its previous attributes")
  func webhookCases() throws {
    let printed = try Self.files(try Self.miniature())
    let event = try Self.file(printed, at: "WebhookEvent.swift", in: .admin)
    let previous = try Self.file(
      printed, at: "WebhookEvent/WebhookEvent.ThingUpdatedPreviousAttributes.swift", in: .admin)

    #expect(event.contains("  case thingCreated(Payload<AdminSchema.ThingEventObject, Never>)\n"))
    #expect(
      event.contains(
        "  case thingUpdated(Payload<AdminSchema.ThingEventObject, ThingUpdatedPreviousAttributes>)\n"
      ))
    #expect(event.contains("  case unknown(AdminSchema.WebhookEvent)\n"))
    #expect(event.contains("    case .thingUpdated: \"thing.updated\"\n"))
    #expect(previous.contains("    public var count: Int64?\n"))
    #expect(previous.contains("    public var updated_at: Date??\n"))
    #expect(
      !printed.values.joined().contains {
        $0.path.hasSuffix("ThingCreatedPreviousAttributes.swift")
      })
  }

  @Test(
    "a webhook whose envelope, object or previous attribute the model does not declare is refused",
    arguments: [
      (
        "\"envelope\": \"WebhookEvent\",\n        \"object\": \"ThingEventObject\",\n        \"previousAttributes\"",
        "\"envelope\": \"ThingEnvelope\",\n        \"object\": \"ThingEventObject\",\n        \"previousAttributes\"",
        "delivered in `ThingEnvelope`"
      ),
      (
        "\"object\": \"ThingEventObject\",\n        \"previousAttributes\"",
        "\"object\": \"Gadget\",\n        \"previousAttributes\"",
        "`Gadget` names no object component"
      ),
      (
        "[\"count\", \"updated_at\", \"kind\", \"old\"]",
        "[\"count\", \"colour\"]",
        "the previous attribute `colour` is no field of `ThingEventObject`"
      ),
    ]
  )
  func refusesUndeclaredWebhooks(original: String, replacement: String, refusal: String) throws {
    let text = try Self.miniature().replacingOccurrences(of: original, with: replacement)

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains(refusal) == true)
  }

  @Test("every member of the envelope is an accessor, a deprecated one read through its storage")
  func webhookAccessors() throws {
    let printed = try Self.files(try Self.miniature())
    let event = try Self.file(printed, at: "WebhookEvent.swift", in: .admin)
    let envelope = try Self.file(
      printed, at: "WebhookEvent/WebhookEvent.Envelope.swift", in: .admin)

    #expect(event.contains("  public var id: String {\n    envelope.id\n  }\n"))
    #expect(event.contains("  public var livemode: Bool? {\n    envelope.livemode\n  }\n"))
    #expect(
      event.contains(
        "  @available(*, deprecated, message: \"The former identifier of the event.\")\n"
          + "  public var legacy_id: String? {\n    envelope._legacy_id\n  }\n"))
    #expect(event.contains("    case .unknown(let event): event\n"))
    #expect(envelope.contains("    var _legacy_id: String? { get }\n"))
    #expect(envelope.contains("extension WebhookEvent.Payload: WebhookEvent.Envelope {}\n"))
    #expect(envelope.contains("extension AdminSchema.WebhookEvent: WebhookEvent.Envelope {}\n"))
  }

  @Test("a payload the case's types do not read is the envelope, its object held as it arrived")
  func webhookUntyped() throws {
    let printed = try Self.files(try Self.miniature())
    let event = try Self.file(printed, at: "WebhookEvent.swift", in: .admin)

    #expect(
      event.contains(
        "    case \"thing.created\": typed = try? Self.thingCreated(Payload(from: decoder))\n"))
    #expect(event.contains("    self = try typed ?? .unknown(Self.untyped(decoder, type: type))\n"))
    #expect(
      event.contains(
        "    var data = AdminSchema.WebhookEventData(object: .unknown(payload.data.object))\n"))
    #expect(event.contains("      type: AdminSchema.WebhookEventType(rawValue: type),\n"))
    #expect(event.contains("    event._legacy_id = payload._legacy_id\n    return event\n"))
  }

  @Test(
    "an envelope an event this build cannot type could not be held in is refused",
    arguments: [
      (
        "\"name\": \"livemode\"",
        "\"name\": \"thingCreated\"",
        "WebhookEvent.thingCreated: read as a case or a member the event holds of its own"
      ),
      (
        "\"name\": \"livemode\"",
        "\"name\": \"envelope\"",
        "WebhookEvent.envelope: read as a case or a member the event holds of its own"
      ),
      (
        "{ \"kind\": \"ref\", \"name\": \"WebhookEventObject\" }",
        "{ \"kind\": \"ref\", \"name\": \"ThingEventObject\" }",
        "data.object: neither a union nor any value"
      ),
      (
        "\"type\": { \"kind\": \"map\", \"values\": { \"kind\": \"any\" } }, \"description\": \"The fields",
        "\"type\": { \"kind\": \"map\", \"values\": { \"kind\": \"string\" } }, \"description\": \"The fields",
        "data.previous_attributes: no map of any value"
      ),
      (
        "\"type\": { \"kind\": \"ref\", \"name\": \"WebhookEventType\" }, \"description\": \"What happened.\"",
        "\"type\": { \"kind\": \"integer\" }, \"description\": \"What happened.\"",
        "WebhookEvent.type: neither a string nor an enum of strings"
      ),
    ]
  )
  func refusesUnholdableEnvelopes(original: String, replacement: String, refusal: String) throws {
    let text = try Self.miniature().replacingOccurrences(of: original, with: replacement)

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains(refusal) == true, "\(Self.refusal(text) ?? "printed")")
  }

  @Test("webhooks that disagree with the members of the envelope's type are refused")
  func refusesDisagreeingTypes() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "{ \"value\": \"thing.updated\", \"name\": \"WebhookEventTypeThingUpdated\" }",
      with: "{ \"value\": \"thing.renamed\", \"name\": \"WebhookEventTypeThingRenamed\" }"
    )

    #expect(
      Self.refusal(text)?.contains(
        "no webhook for thing.renamed; no member for thing.updated; each type is one webhook and one member"
      ) == true)
  }

  @Test("two types read as one case are refused, never renamed")
  func refusesFoldedTypes() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"type\": \"thing.created\"",
      with: "\"type\": \"thing_updated\""
    )

    #expect(
      Self.refusal(text)?.contains("read as `thingUpdated`, the case `thing_updated` is read as")
        == true)
  }

  @Test("webhooks on the Tile API, which sends none, are refused rather than read past")
  func refusesTileWebhooks() throws {
    let text = try Self.miniature().replacingOccurrences(
      of: "\"origin\": \"https://tiles.example.com\",",
      with:
        "\"origin\": \"https://tiles.example.com\", \"webhooks\": [{ \"type\": \"spec.updated\", "
        + "\"unit\": \"admin\", \"envelope\": \"WebhookEvent\", \"object\": \"Spec\" }],"
    )

    #expect(
      Self.refusal(text)?.contains(
        "tiles.webhooks: webhooks on a surface this printer prints none for") == true)
  }

  /// The model states every entry's unit, and the printer splits by it and by no list of its own
  /// (SPEC.md section 3): the admin group's operations, the components only it and the webhooks
  /// reach, their facts and the webhook event print into `MountayaAdmin`, and nothing of them into
  /// the core.
  @Test("the admin unit's group, components, facts and webhook event print into MountayaAdmin")
  func unitsSplit() throws {
    let printed = try Self.files(try Self.miniature())
    let core = (printed[.core] ?? []).map(\.path)

    #expect(
      (printed[.admin] ?? []).map(\.path) == [
        "AdminSchema.swift",
        "AdminSchema/AdminSchema.PostThingUploadBody.swift",
        "AdminSchema/AdminSchema.PostThingUploadMultipartBody.swift",
        "AdminSchema/AdminSchema.ThingEventObject.swift",
        "AdminSchema/AdminSchema.WebhookEvent.swift",
        "AdminSchema/AdminSchema.WebhookEventData.swift",
        "AdminSchema/AdminSchema.WebhookEventObject.swift",
        "AdminSchema/AdminSchema.WebhookEventType.swift",
        "Mountaya/Mountaya.Admin.Exports.swift",
        "Mountaya/Mountaya.Admin.swift",
        "OperationFacts/OperationFacts.Admin.swift",
        "WebhookEvent.swift",
        "WebhookEvent/WebhookEvent.Envelope.swift",
        "WebhookEvent/WebhookEvent.Payload.swift",
        "WebhookEvent/WebhookEvent.PayloadData.swift",
        "WebhookEvent/WebhookEvent.ThingUpdatedPreviousAttributes.swift",
      ])
    #expect(core.contains("RestSchema/RestSchema.Thing.swift"))
    #expect(core.contains("Mountaya/Mountaya.Studio.Things.swift"))
    #expect(
      !core.contains { $0.contains("Admin") || $0.contains("Webhook") || $0.contains("PostThing") },
      "\(core)")
    let facts = try Self.file(printed, at: "OperationFacts/OperationFacts.Rest.swift")
    #expect(!facts.contains("deleteThing"), "the core's table holds no operation of the admin unit")
  }

  @Test("a type of the admin unit names the core's in RestSchema and its own in AdminSchema")
  func crossUnitNames() throws {
    let printed = try Self.files(try Self.miniature())
    let exports = try Self.file(printed, at: "Mountaya/Mountaya.Admin.Exports.swift", in: .admin)
    let object = try Self.file(
      printed, at: "AdminSchema/AdminSchema.ThingEventObject.swift", in: .admin)
    let accessor = try Self.file(printed, at: "Mountaya/Mountaya.Admin.swift", in: .admin)
    let facts = try Self.file(printed, at: "OperationFacts/OperationFacts.Admin.swift", in: .admin)

    #expect(
      exports.contains("\nimport Foundation\nimport MountayaClient\n\nextension Mountaya.Admin {\n")
    )
    #expect(exports.contains("      kind: RestSchema.ThingKind,\n"))
    #expect(exports.contains("      body: AdminSchema.PostThingUploadBody,\n"))
    #expect(exports.contains("    ) async throws -> Response<JSONValue, RestSchema.ListMeta?> {\n"))
    #expect(object.contains("    public var kind: RestSchema.ThingKind\n"))
    #expect(accessor.contains("  public var admin: Admin {\n    Admin(sender: sender)\n  }\n"))
    #expect(accessor.contains("importing `MountayaAdmin` is the whole of what a call into it asks"))
    #expect(
      facts.contains("  static let adminOperations: [OperationFacts] = [\n    .getThingExport,"))
    #expect(!(try Self.file(printed, at: "SchemaVersion.swift")).contains("import MountayaClient"))
  }

  @Test(
    "an entry that states no unit, or a unit the printer does not know, is refused, never guessed",
    arguments: [
      (
        "\"namespace\": \"admin.exports\",\n        \"unit\": \"admin\",\n        \"scope\": \"management\",\n        \"idempotent\": true,\n        \"timeoutMs\": 30000,\n        \"idempotencyKey\": false,",
        "\"namespace\": \"admin.exports\",\n        \"scope\": \"management\",\n        \"idempotent\": true,\n        \"timeoutMs\": 30000,\n        \"idempotencyKey\": false,",
        "model.rest.operations[5]: no `unit`"
      ),
      (
        "\"type\": \"thing.updated\",\n        \"unit\": \"admin\",",
        "\"type\": \"thing.updated\",\n        \"unit\": \"server\",",
        "model.rest.webhooks[1].unit: `server`, which this printer does not know"
      ),
    ]
  )
  func refusesUnits(original: String, replacement: String, refusal: String) throws {
    let text = try Self.miniature().replacingOccurrences(of: original, with: replacement)

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains(refusal) == true, "\(Self.refusal(text) ?? "printed")")
  }

  @Test(
    "what one unit cannot print is refused by name: a group of two units, the Tile API in the admin unit, webhooks of two units and the core naming the admin unit's component",
    arguments: [
      (
        "\"path\": \"/v1/things/{thing_id}\",\n        \"namespace\": \"admin.exports\",\n        \"unit\": \"admin\",",
        "\"path\": \"/v1/things/{thing_id}\",\n        \"namespace\": \"admin.exports\",\n        \"unit\": \"core\",",
        "rest.deleteThing: the core unit's, and `getThingExport` of its group `admin` the admin unit's"
      ),
      (
        "\"path\": \"/v1/spec\",\n        \"unit\": \"core\",",
        "\"path\": \"/v1/spec\",\n        \"unit\": \"admin\",",
        "getSpec: the admin unit's, and the Tile API and the templates are printed in the core alone"
      ),
      (
        "\"type\": \"thing.created\",\n        \"unit\": \"admin\",",
        "\"type\": \"thing.created\",\n        \"unit\": \"core\",",
        "rest.webhooks: events of both units"
      ),
      (
        "\"name\": \"ThingKind\",\n        \"kind\": \"enum\",\n        \"usage\": [\"request\", \"response\"],\n        \"unit\": \"core\",",
        "\"name\": \"ThingKind\",\n        \"kind\": \"enum\",\n        \"usage\": [\"request\", \"response\"],\n        \"unit\": \"admin\",",
        "RestSchema: the core names `ThingKind`, a component of the admin unit"
      ),
    ]
  )
  func refusesSplits(original: String, replacement: String, refusal: String) throws {
    let text = try Self.miniature().replacingOccurrences(of: original, with: replacement)

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains(refusal) == true, "\(Self.refusal(text) ?? "printed")")
  }

  @Test(
    "a deprecated declaration carries its description's first sentence, and only a caller warns")
  func deprecation() throws {
    let printed = try Self.files(try Self.miniature())
    let thing = try Self.file(printed, at: "RestSchema/RestSchema.Thing.swift")
    let things = try Self.file(printed, at: "Mountaya/Mountaya.Studio.Things.swift")

    #expect(thing.contains("    @available(*, deprecated, message: \"The former name.\")\n"))
    #expect(thing.contains("    public var old: String? {\n      get { _old }\n"))
    #expect(thing.contains("      self._old = try container.decodeIfPresent("))
    #expect(things.contains("@available(*, deprecated, message: \"Update a thing.\")"))
  }

  @Test("an enum member is named by its words in lowerCamelCase, a keyword escaped where declared")
  func memberNames() throws {
    let printed = try Self.files(try Self.miniature())
    let kind = try Self.file(printed, at: "RestSchema/RestSchema.ThingKind.swift")
    let scope = try Self.file(printed, at: "RestSchema/RestSchema.ThingScope.swift")
    let size = try Self.file(printed, at: "RestSchema/RestSchema.TileSize.swift")
    let lookup = try Self.file(printed, at: "DataSchema/DataSchema.LookupKind.swift")

    #expect(kind.contains("    public static let smallOne: Self = \"small-one\"\n"))
    #expect(kind.contains("    public static let kind2xl: Self = \"2xl\"\n"))
    #expect(scope.contains("    public static let `internal`: Self = \"internal\"\n"))
    #expect(size.contains("    public static let size256: Self = 256\n"))
    #expect(lookup.contains("    public static let roundTrip: Self = \"ROUND_TRIP\"\n"))
    #expect(lookup.contains("    public static let mtb0: Self = \"MTB_0\"\n"))
  }

  @Test(
    "a REST member's words are its name less its type's, a first digit keeping the type's last word",
    arguments: [
      ("TileLayerTypeLine", "TileLayerType", "line"),
      ("TileSourceTypeRasterDem", "TileSourceType", "rasterDem"),
      ("ElevationTileSize512", "ElevationTileSize", "size512"),
      ("UsageStatusClass2xx", "UsageStatusClass", "class2xx"),
      ("WebhookHealthWindow24h", "WebhookHealthWindow", "window24h"),
      ("TrailDifficultyTypeMtb0", "TrailDifficultyType", "mtb0"),
      ("ManeuverTypeContinue", "ManeuverType", "continue"),
    ]
  )
  func restMemberWords(name: String, type: String, member: String) throws {
    #expect(try MemberWords.rest(name, of: type, in: "RestSchema") == member)
  }

  @Test(
    "a Data API member's words are its name split at each underscore",
    arguments: [
      ("HIKING_AND_TRAIL", "ActivitySlug", "hikingAndTrail"),
      ("MTB_0", "TrailDifficultyType", "mtb0"),
      ("FROM_25_TO_30", "SteepnessBand", "from25To30"),
      ("PLACES", "SearchTarget", "places"),
      ("CONTINUE", "ManeuverType", "continue"),
    ]
  )
  func dataMemberWords(name: String, type: String, member: String) throws {
    #expect(try MemberWords.data(name, of: type, in: "DataSchema") == member)
  }

  @Test("a member's name is escaped where it is declared and only where Swift reserves it")
  func memberKeywords() {
    #expect(SwiftText.identifier("continue") == "`continue`")
    #expect(SwiftText.identifier("true") == "`true`")
    #expect(SwiftText.identifier("private") == "`private`")
    #expect(SwiftText.identifier("open") == "`open`")
    #expect(SwiftText.identifier("none") == "none")
  }

  @Test(
    "a member no words can be read off is refused, never printed under its whole name",
    arguments: [
      (
        "\"name\": \"ThingKindBig\"", "\"name\": \"KindBig\"",
        "RestSchema.ThingKind.KindBig: does not start with its type's name"
      ),
      (
        "\"name\": \"ThingKindBig\"", "\"name\": \"ThingKindbig\"",
        "RestSchema.ThingKind.ThingKindbig: leaves no words after its type's name, each"
      ),
      (
        "\"name\": \"ThingKindBig\"", "\"name\": \"ThingKind\"",
        "RestSchema.ThingKind.ThingKind: leaves no words after its type's name"
      ),
      (
        "{ \"name\": \"ROUND_TRIP\" }", "{ \"name\": \"ROUND__TRIP\" }",
        "DataSchema.LookupKind.ROUND__TRIP: is no words split at each underscore"
      ),
    ]
  )
  func refusesWordlessMembers(original: String, replacement: String, refusal: String) throws {
    let text = try Self.miniature().replacingOccurrences(of: original, with: replacement)

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains(refusal) == true, "\(Self.refusal(text) ?? "printed")")
  }

  @Test(
    "two members of one name, compared without regard to case, are refused, never renamed",
    arguments: [
      (
        [
          ("\"name\": \"ThingScopeAudit\"", "\"name\": \"ThingScopeReadAll\""),
          ("\"name\": \"ThingScopeRead\"", "\"name\": \"ThingScopeReadall\""),
        ],
        "RestSchema.ThingScope: `ThingScopeReadall` and `ThingScopeReadAll` are both named `readAll`"
      ),
      (
        [("{ \"name\": \"MTB_0\" }", "{ \"name\": \"ROUNDTRIP\" }")],
        "DataSchema.LookupKind: `ROUND_TRIP` and `ROUNDTRIP` are both named `roundtrip`"
      ),
    ]
  )
  func refusesMemberCollisions(replacements: [(String, String)], refusal: String) throws {
    var text = try Self.miniature()
    for (original, replacement) in replacements {
      text = text.replacingOccurrences(of: original, with: replacement)
    }

    #expect(text != (try Self.miniature()))
    #expect(Self.refusal(text)?.contains(refusal) == true, "\(Self.refusal(text) ?? "printed")")
  }

  @Test(
    "a member named as its type names one of its own is refused",
    arguments: [
      (
        "\"name\": \"ThingScopeAudit\"", "\"name\": \"ThingScopeRawValue\"",
        "ThingScope.ThingScopeRawValue", "rawValue"
      ),
      ("{ \"name\": \"MTB_0\" }", "{ \"name\": \"INIT\" }", "LookupKind.INIT", "init"),
      (
        "{ \"name\": \"MTB_0\" }", "{ \"name\": \"HASH_VALUE\" }", "LookupKind.HASH_VALUE",
        "hashValue"
      ),
      (
        "{ \"name\": \"MTB_0\" }", "{ \"name\": \"ALL_CASES\" }", "LookupKind.ALL_CASES", "allCases"
      ),
    ]
  )
  func refusesOwnMemberNames(original: String, replacement: String, site: String, name: String)
    throws
  {
    let text = try Self.miniature().replacingOccurrences(of: original, with: replacement)

    #expect(text != (try Self.miniature()))
    #expect(
      Self.refusal(text)?.contains("\(site): named `\(name)`, a name the type holds of its own")
        == true,
      "\(Self.refusal(text) ?? "printed")")
  }

  @Test("a name is escaped only where Swift would not read it as an identifier")
  func identifiers() {
    #expect(SwiftText.identifier("itinerary_id") == "itinerary_id")
    #expect(SwiftText.identifier("default") == "`default`")
    #expect(SwiftText.identifier("Last-Event-ID") == "`Last-Event-ID`")
    #expect(SwiftText.identifier("3d") == "`3d`")
    #expect(SwiftText.literal("a \"b\"\n\\") == #""a \"b\"\n\\""#)
  }

  @Test("a doc comment keeps within the column, breaking at spaces")
  func docLines() {
    let long = String(repeating: "word ", count: 60)
    let lines = SwiftText.docLines(long + "\n\n  indented", indent: 6)

    #expect(lines.allSatisfy { $0.count <= SwiftText.lineLength })
    #expect(lines.contains("      ///"))
    #expect(lines.last == "      ///   indented")
  }
}
