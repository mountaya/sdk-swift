import GateSupport

/// Model is `sdk/model.json` from `mountaya/schemas`, read into what the printer walks.
///
/// The reader refuses a `modelVersion` it was not written for and a `kind` it does not know,
/// and ignores a key it does not know, which is how the model's own README asks to be read.
package struct Model: Sendable {
  /// supportedVersion is the one `modelVersion` this printer was written for.
  package static let supportedVersion = 2

  package let contract: String
  package let rest: Surface
  package let tiles: Surface
  package let data: DataSurface

  /// parse reads the model's text.
  package static func parse(_ text: String) throws(PrinterError) -> Model {
    let json: OrderedJSON
    do {
      json = try OrderedJSON.parse(text)
    } catch {
      throw PrinterError("sdk/model.json is not JSON: \(error)")
    }
    let reader = Reader(json, at: "model")
    let version = try reader.integer("modelVersion")
    guard version == supportedVersion else {
      throw PrinterError(
        "sdk/model.json is modelVersion \(version), and this printer reads \(supportedVersion)"
      )
    }
    return Model(
      contract: try reader.string("contract"),
      rest: try Surface(try reader.object("rest"), name: "rest"),
      tiles: try Surface(try reader.object("tiles"), name: "tiles"),
      data: try DataSurface(try reader.object("data"))
    )
  }
}

/// PrinterError says what the printer refused and where.
package struct PrinterError: Error, Sendable, CustomStringConvertible {
  package let description: String

  package init(_ description: String) {
    self.description = description
  }
}

/// ClientUnit is one of the two units a client ships as (`sdk/SPEC.md`, "The three layers, in every
/// language"): the core, `MountayaClient`, and the admin unit, `MountayaAdmin`, which the model
/// states of every operation, template, webhook event and component as `unit`.
package enum ClientUnit: String, Sendable, CaseIterable {
  case core
  case admin

  /// module is the target the unit's printed files are compiled in.
  package var module: String {
    switch self {
    case .core: "MountayaClient"
    case .admin: "MountayaAdmin"
    }
  }

  /// Reads an entry's `unit`, refusing an entry that states none and a unit this printer does
  /// not know, since a printer that guessed one would put a type in a target that may not
  /// compile without the other.
  init(_ reader: Reader) throws(PrinterError) {
    let unit = try reader.string("unit")
    guard let known = ClientUnit(rawValue: unit) else {
      throw PrinterError("\(reader.path).unit: `\(unit)`, which this printer does not know")
    }
    self = known
  }
}

// MARK: - The OpenAPI surfaces

/// Surface is one OpenAPI surface: REST or Tiles.
package struct Surface: Sendable {
  package let origin: String
  package let operations: [Operation]
  /// templates is the routes a map renderer fetches on its own, which no method binds. They are
  /// read, so a kind the printer does not know is refused there too, and printed as URL
  /// templates, each its path, its parameters and the media types it answers in.
  package let templates: [Operation]
  package let schemas: [Schema]
  /// webhooks is every public event type the surface sends an endpoint, in the model's order,
  /// and empty for a surface that sends none, which the model leaves the key out of.
  package let webhooks: [Webhook]

  init(_ reader: Reader, name: String) throws(PrinterError) {
    origin = try reader.string("origin")
    operations = try reader.array("operations").map { item throws(PrinterError) in
      try Operation(item)
    }
    templates = try (reader.optionalArray("templates") ?? []).map {
      item throws(PrinterError) in try Operation(item)
    }
    schemas = try reader.array("schemas").map { item throws(PrinterError) in try Schema(item) }
    webhooks = try (reader.optionalArray("webhooks") ?? []).map {
      item throws(PrinterError) in try Webhook(item)
    }
    for template in templates {
      guard case .binary = template.success else {
        throw PrinterError(
          "\(name).templates.\(template.operationId): a template that is not binary")
      }
    }
  }
}

/// Webhook is one public webhook event type: the envelope it is delivered in, the object its
/// `data.object` holds, and the fields its `data.previous_attributes` can carry.
package struct Webhook: Sendable {
  /// type is the event's type, as the wire spells it: `organization.member.updated`.
  package let type: String
  /// unit is the unit the event is received in.
  package let unit: ClientUnit
  /// envelope is the component the event is delivered as.
  package let envelope: String
  /// object is the component its `data.object` holds.
  package let object: String
  /// previousAttributes is each field of `object` its `data.previous_attributes` can carry, in
  /// the model's order, and empty for a type whose change moves none.
  package let previousAttributes: [String]
  package let summary: String?
  package let description: String?

  init(_ reader: Reader) throws(PrinterError) {
    type = try reader.string("type")
    unit = try ClientUnit(reader)
    envelope = try reader.string("envelope")
    object = try reader.string("object")
    previousAttributes = try (reader.optionalArray("previousAttributes") ?? []).map {
      item throws(PrinterError) in try item.stringValue()
    }
    summary = try reader.optionalString("summary")
    description = try reader.optionalString("description")
  }
}

/// TypeNode is one type, and whether it may be null.
package struct TypeNode: Sendable {
  package indirect enum Kind: Sendable {
    case string(format: String?, const: String?, inlineEnum: InlineEnum?)
    case integer(format: String?, const: Double?)
    case number(format: String?)
    case boolean(const: Bool?)
    case array(TypeNode)
    case map(values: TypeNode, keys: TypeNode?)
    case object(InlineObject)
    case union(name: String, members: [TypeNode])
    case ref(String)
    /// null is a value that is always null, which a success with no payload declares at `data`.
    case null
    case any
  }

  package let kind: Kind
  package let nullable: Bool

  init(_ reader: Reader) throws(PrinterError) {
    nullable = try reader.optionalBool("nullable") ?? false
    let kind = try reader.string("kind")
    switch kind {
    case "string":
      let values = try reader.optionalArray("enum")
      self.kind = .string(
        format: try reader.optionalString("format"),
        const: try reader.optionalString("const"),
        inlineEnum: try values.map { values throws(PrinterError) in
          InlineEnum(
            name: try reader.string("name"),
            values: try values.map { value throws(PrinterError) in try value.stringValue() },
            names: try reader.optionalArray("enumNames")?.map { name throws(PrinterError) in
              try name.stringValue()
            }
          )
        }
      )
    case "integer":
      self.kind = .integer(
        format: try reader.optionalString("format"),
        const: try reader.optionalNumber("const")
      )
    case "number":
      self.kind = .number(format: try reader.optionalString("format"))
    case "boolean":
      self.kind = .boolean(const: try reader.optionalBool("const"))
    case "array":
      self.kind = .array(try TypeNode(try reader.object("items")))
    case "map":
      self.kind = .map(
        values: try TypeNode(try reader.object("values")),
        keys: try reader.optionalObject("keys").map { keys throws(PrinterError) in
          try TypeNode(keys)
        }
      )
    case "object":
      self.kind = .object(try InlineObject(reader))
    case "union":
      self.kind = .union(
        name: try reader.string("name"),
        members: try reader.array("members").map { item throws(PrinterError) in
          try TypeNode(item)
        }
      )
    case "ref":
      self.kind = .ref(try reader.string("name"))
    case "null":
      self.kind = .null
    case "any":
      self.kind = .any
    default:
      throw PrinterError(
        "\(reader.path): a type of kind `\(kind)`, which this printer does not know")
    }
  }

  init(kind: Kind, nullable: Bool) {
    self.kind = kind
    self.nullable = nullable
  }
}

/// InlineEnum is a closed set of strings written inline, which the model names from where it
/// sits.
package struct InlineEnum: Sendable {
  package let name: String
  package let values: [String]
  /// names is each value's `x-enum-varnames` name, the type's name followed by the value's own
  /// words (`GetZonesSortUpdatedAtDescending`), in the values' order, or nil where the model
  /// states none and each member is printed under its wire spelling.
  package let names: [String]?
}

/// InlineObject is an object written inline, which the model names from where it sits.
package struct InlineObject: Sendable {
  package let name: String
  package let properties: [Property]
  /// allowsOtherKeys is true where the object lets keys it does not name through.
  package let allowsOtherKeys: Bool
  /// isClosed is true where the object refuses every key it does not declare, as every object
  /// a request body reaches does.
  package let isClosed: Bool

  init(_ reader: Reader) throws(PrinterError) {
    name = try reader.string("name")
    properties = try (reader.optionalArray("properties") ?? []).map {
      item throws(PrinterError) in try Property(item)
    }
    allowsOtherKeys = reader.json["additional"] != nil
    isClosed = try reader.optionalBool("closed") ?? false
    guard !(isClosed && allowsOtherKeys) else {
      throw PrinterError("\(reader.path): an object both closed and open to other keys")
    }
  }
}

/// Property is one member of an object.
package struct Property: Sendable {
  /// Direction is which way a property travels, where the bundle says it travels one way only.
  package enum Direction: Sendable {
    /// readOnly is written by the server, and a request never sends it.
    case readOnly
    /// writeOnly is sent by a request, and the server never answers it.
    case writeOnly
  }

  package let name: String
  package let required: Bool
  package let type: TypeNode
  package let description: String?
  package let discriminatorValue: String?
  package let deprecated: Bool
  /// from is the parent component a composed component inherits the property from, or nil for
  /// a property of its own.
  package let from: String?
  /// direction is the one way the property travels, or nil where it travels both.
  package let direction: Direction?
  /// secret is true where the property's value is a secret, a credential for as long as it lives,
  /// which a printed type never prints (`sdk/SPEC.md` §1).
  package let secret: Bool

  init(_ reader: Reader) throws(PrinterError) {
    name = try reader.string("name")
    required = try reader.bool("required")
    type = try TypeNode(try reader.object("type"))
    description = try reader.optionalString("description")
    discriminatorValue = try reader.optionalString("discriminatorValue")
    deprecated = try reader.optionalBool("deprecated") ?? false
    from = try reader.optionalString("from")
    secret = try reader.optionalBool("secret") ?? false
    let readOnly = try reader.optionalBool("readOnly") ?? false
    let writeOnly = try reader.optionalBool("writeOnly") ?? false
    switch (readOnly, writeOnly) {
    case (true, true):
      throw PrinterError("\(reader.path): a property both read-only and write-only")
    case (true, false): direction = .readOnly
    case (false, true): direction = .writeOnly
    case (false, false): direction = nil
    }
  }

  init(
    name: String,
    required: Bool,
    type: TypeNode,
    description: String?,
    discriminatorValue: String?,
    deprecated: Bool
  ) {
    self.name = name
    self.required = required
    self.type = type
    self.description = description
    self.discriminatorValue = discriminatorValue
    self.deprecated = deprecated
    self.from = nil
    self.direction = nil
    self.secret = false
  }
}

/// Schema is one component.
package struct Schema: Sendable {
  package enum Kind: Sendable {
    /// object is a component of properties, a composed one flattened with its parents' first,
    /// which `extends` names.
    case object(properties: [Property], allowsOtherKeys: Bool, isClosed: Bool, extends: [String])
    case enumeration(valueType: String, members: [EnumMember])
    case union(discriminator: String, members: [UnionMember])
    case alias(TypeNode)
    case geojson(geometry: String)
  }

  package let name: String
  package let kind: Kind
  /// unit is the unit the component is printed in: the admin unit's where only that unit
  /// reaches it.
  package let unit: ClientUnit
  /// isEnvelope is true for a schema of the response envelope every operation shares, which an
  /// SDK declares once by hand.
  package let isEnvelope: Bool
  package let usage: [String]
  package let description: String?

  init(_ reader: Reader) throws(PrinterError) {
    name = try reader.string("name")
    unit = try ClientUnit(reader)
    isEnvelope = try reader.optionalString("role") == "envelope"
    usage = try reader.array("usage").map { item throws(PrinterError) in try item.stringValue() }
    description = try reader.optionalString("description")
    let kind = try reader.string("kind")
    switch kind {
    case "object":
      let properties = try (reader.optionalArray("properties") ?? []).map {
        item throws(PrinterError) in try Property(item)
      }
      let extends = try (reader.optionalArray("extends") ?? []).map {
        item throws(PrinterError) in try item.stringValue()
      }
      for property in properties {
        guard let parent = property.from else { continue }
        guard extends.contains(parent) else {
          throw PrinterError(
            "\(reader.path).\(property.name): inherited from `\(parent)`, which it does not extend"
          )
        }
      }
      let allowsOtherKeys = reader.json["additional"] != nil
      let isClosed = try reader.optionalBool("closed") ?? false
      guard !(isClosed && allowsOtherKeys) else {
        throw PrinterError("\(reader.path): a component both closed and open to other keys")
      }
      for property in properties {
        if property.direction == .readOnly, usage.contains("request") {
          throw PrinterError(
            "\(reader.path).\(property.name): read-only on a component a request sends")
        }
        if property.direction == .writeOnly, usage.contains("response") {
          throw PrinterError(
            "\(reader.path).\(property.name): write-only on a component a response carries")
        }
      }
      self.kind = .object(
        properties: properties,
        allowsOtherKeys: allowsOtherKeys,
        isClosed: isClosed,
        extends: extends
      )
    case "enum":
      self.kind = .enumeration(
        valueType: try reader.string("valueType"),
        members: try reader.array("members").map { item throws(PrinterError) in
          try EnumMember(item)
        }
      )
    case "union":
      self.kind = .union(
        discriminator: try reader.string("discriminator"),
        members: try reader.array("members").map { item throws(PrinterError) in
          UnionMember(value: try item.string("value"), type: try item.string("type"))
        }
      )
    case "alias":
      self.kind = .alias(try TypeNode(try reader.object("type")))
    case "geojson":
      self.kind = .geojson(geometry: try reader.string("geometry"))
    default:
      throw PrinterError(
        "\(reader.path): a schema of kind `\(kind)`, which this printer does not know")
    }
  }
}

/// EnumMember is one value of an enum, as the wire spells it and as `x-enum-varnames` names it.
package struct EnumMember: Sendable {
  /// value is a string, or an integer for an enum whose `valueType` is `integer`.
  package let value: OrderedJSON
  package let name: String
  package let description: String?
  package let deprecated: Bool
  /// includes is the values this one reaches what they reach, `x-pkey-scope-includes`.
  package let includes: [String]
  /// needs is the values a key carrying this one must carry beside it, `x-pkey-scope-needs`.
  package let needs: [String]

  init(_ reader: Reader) throws(PrinterError) {
    guard let value = reader.json["value"] else {
      throw PrinterError("\(reader.path): an enum member with no `value`")
    }
    self.value = value
    name = try reader.string("name")
    description = try reader.optionalString("description")
    deprecated = try reader.optionalBool("deprecated") ?? false
    includes = try (reader.optionalArray("includes") ?? []).map {
      item throws(PrinterError) in try item.stringValue()
    }
    needs = try (reader.optionalArray("needs") ?? []).map {
      item throws(PrinterError) in try item.stringValue()
    }
  }
}

/// UnionMember is one member of a discriminated union, and the discriminator value naming it.
package struct UnionMember: Sendable {
  package let value: String
  package let type: String
}

/// Parameter is one path, query or header parameter.
package struct Parameter: Sendable {
  package let name: String
  package let required: Bool
  package let type: TypeNode
  package let description: String?
  package let deprecated: Bool

  init(_ reader: Reader, alwaysRequired: Bool) throws(PrinterError) {
    name = try reader.string("name")
    required = alwaysRequired ? true : (try reader.optionalBool("required") ?? false)
    type = try TypeNode(try reader.object("type"))
    description = try reader.optionalString("description")
    deprecated = try reader.optionalBool("deprecated") ?? false
  }
}

/// Operation is one operation a client emits, or one route a map renderer fetches on its own.
package struct Operation: Sendable {
  /// Credentials is the six facts an operation declares about the credentials it takes.
  package struct Credentials: Sendable {
    /// actingUser is the operation's `x-acting-user`: `required`, `optional` or `none`.
    package let actingUser: String
    package let acceptsShareToken: Bool
    package let requiresSession: Bool
    package let requiresSecretKey: Bool
    package let takesNoCredential: Bool
    package let pendingInvitee: Bool

    /// The values `x-acting-user` takes.
    static let actingUsers: Set<String> = ["required", "optional", "none"]

    /// Reads the facts an operation's `credentials` states, refusing an acting user this printer
    /// does not know.
    init(_ credentials: Reader) throws(PrinterError) {
      let actingUser = try credentials.string("actingUser")
      guard Self.actingUsers.contains(actingUser) else {
        throw PrinterError(
          "\(credentials.path).actingUser: `\(actingUser)`, which this printer does not know")
      }
      self.actingUser = actingUser
      acceptsShareToken = try credentials.bool("acceptsShareToken")
      requiresSession = try credentials.bool("requiresSession")
      requiresSecretKey = try credentials.bool("requiresSecretKey")
      takesNoCredential = try credentials.bool("takesNoCredential")
      pendingInvitee = try credentials.bool("pendingInvitee")
    }
  }

  /// Body is one media type a request body may be sent in.
  package struct BodyContent: Sendable {
    package let mediaType: String
    package let type: TypeNode
    /// encoding is, on a form, the media type each part the model names carries where its caller
    /// names none, by the part's property, in the model's order.
    package let encoding: [(property: String, contentType: String)]
  }

  /// Success is what a successful answer carries, one shape however many statuses answer it.
  package enum Success: Sendable {
    case envelope(data: TypeNode?, metadata: (required: Bool, type: TypeNode)?)
    case eventStream(event: TypeNode)
    case binary(mediaTypes: [String])
  }

  /// Header is one header a success declares.
  package struct Header: Sendable {
    package let name: String
    package let required: Bool
    package let type: TypeNode
  }

  /// SuccessResponse is one status a success answers with, and the headers it declares.
  package struct SuccessResponse: Sendable {
    package let status: Int
    package let headers: [Header]

    /// all reads every status a success states, refusing a success that states none.
    static func all(in success: Reader) throws(PrinterError) -> [SuccessResponse] {
      let responses = try success.array("responses").map { item throws(PrinterError) in
        SuccessResponse(
          status: try item.integer("status"),
          headers: try item.array("headers").map { header throws(PrinterError) in
            Header(
              name: try header.string("name"),
              required: try header.bool("required"),
              type: try TypeNode(try header.object("type"))
            )
          }
        )
      }
      guard !responses.isEmpty else {
        throw PrinterError("\(success.path): a success that names no status")
      }
      return responses
    }
  }

  /// Document is a JSON document a template's route answers, which a renderer reads as it
  /// arrives.
  package struct Document: Sendable {
    package let mediaType: String
    package let type: TypeNode
  }

  /// Pagination is how an operation that pages by cursor sorts, and how many rows a page holds
  /// where the caller names no `limit`.
  package struct Pagination: Sendable {
    package let sort: [String]
    package let defaultSort: String?
    /// defaultLimit is the `default` its `limit` parameter states, the page size a walk asks for
    /// where its caller names none, or nil where it states none.
    package let defaultLimit: Int?
  }

  /// ErrorStatus is one failing status the operation declares, and the metadata it adds.
  package struct ErrorStatus: Sendable {
    package let status: Int
    package let metadata: (required: Bool, type: TypeNode)?
  }

  package let operationId: String
  package let method: String
  package let path: String
  package let namespace: String?
  /// unit is the unit the operation is printed in.
  package let unit: ClientUnit
  package let idempotent: Bool
  /// timeoutMs is the operation's `x-timeout-ms`, nil for an event stream, which states none.
  package let timeoutMs: Int?
  /// idempotencyKey is true where the operation declares `Idempotency-Key`.
  package let idempotencyKey: Bool
  /// conditional is true where the operation declares `If-Match`.
  package let conditional: Bool
  /// notModified is true where a conditional read is answered with a 304.
  package let notModified: Bool
  package let credentials: Credentials
  package let pathParameters: [Parameter]
  package let queryParameters: [Parameter]
  package let headerParameters: [Parameter]
  package let pagination: Pagination?
  package let bodyRequired: Bool
  package let bodyContent: [BodyContent]
  package let success: Success
  package let successResponses: [SuccessResponse]
  package let documents: [Document]
  package let errors: [ErrorStatus]
  /// tasks is every task the operation triggers, as the contract's `tasks.yaml` names them: one,
  /// or several where the request decides which, and none for a read.
  package let tasks: [String]
  package let summary: String?
  package let description: String?
  package let deprecated: Bool

  /// The headers the client sends itself, which the model never lists as a caller's.
  static let clientHeaders: Set<String> = [
    "accept-language", "idempotency-key", "if-match", "last-event-id",
  ]

  /// asciiLowercase is `name` with only `A` to `Z` lowered, the fold the client compares a
  /// header's name by, so the printer refuses exactly the names the client would.
  static func asciiLowercase(_ name: String) -> String {
    String(
      decoding: name.utf8.map { (0x41...0x5A).contains($0) ? $0 + 0x20 : $0 }, as: UTF8.self)
  }

  /// errorStatuses is every failing status the operation declares, in ascending order.
  package var errorStatuses: [Int] {
    errors.map(\.status).sorted()
  }

  init(_ reader: Reader) throws(PrinterError) {
    operationId = try reader.string("operationId")
    method = try reader.string("method")
    path = try reader.string("path")
    namespace = try reader.optionalString("namespace")
    unit = try ClientUnit(reader)
    idempotent = try reader.bool("idempotent")
    timeoutMs = try reader.optionalInteger("timeoutMs")
    idempotencyKey = try reader.bool("idempotencyKey")
    conditional = try reader.bool("conditional")
    notModified = try reader.optionalBool("notModified") ?? false
    credentials = try Credentials(try reader.object("credentials"))
    pathParameters = try (reader.optionalArray("pathParameters") ?? []).map {
      item throws(PrinterError) in try Parameter(item, alwaysRequired: true)
    }
    queryParameters = try (reader.optionalArray("queryParameters") ?? []).map {
      item throws(PrinterError) in try Parameter(item, alwaysRequired: false)
    }
    headerParameters = try (reader.optionalArray("headerParameters") ?? []).map {
      item throws(PrinterError) in try Parameter(item, alwaysRequired: false)
    }
    for header in headerParameters {
      guard Self.clientHeaders.contains(Self.asciiLowercase(header.name)) else { continue }
      throw PrinterError(
        "\(reader.path): `\(header.name)` among the caller's headers, where the client sends it")
    }
    if let pagination = try reader.optionalObject("pagination") {
      var defaultLimit: Int?
      for item in try reader.optionalArray("queryParameters") ?? [] {
        if try item.string("name") == "limit" {
          defaultLimit = try item.optionalInteger("default")
        }
      }
      self.pagination = Pagination(
        sort: try pagination.array("sort").map { item throws(PrinterError) in
          try item.stringValue()
        },
        defaultSort: try pagination.optionalString("defaultSort"),
        defaultLimit: defaultLimit
      )
      for name in ["cursor", "limit"] where !queryParameters.contains(where: { $0.name == name }) {
        throw PrinterError("\(reader.path): it pages by cursor and takes no `\(name)`")
      }
    } else {
      pagination = nil
    }
    if let body = try reader.optionalObject("requestBody") {
      bodyRequired = try body.bool("required")
      bodyContent = try body.array("content").map { item throws(PrinterError) in
        BodyContent(
          mediaType: try item.string("mediaType"),
          type: try TypeNode(try item.object("type")),
          encoding: try (item.optionalArray("encoding") ?? []).map { entry throws(PrinterError) in
            (try entry.string("property"), try entry.string("contentType"))
          }
        )
      }
    } else {
      bodyRequired = false
      bodyContent = []
    }

    let success = try reader.object("success")
    let kind = try success.string("kind")
    switch kind {
    case "envelope":
      let data = try success.optionalObject("data").map { data throws(PrinterError) in
        try TypeNode(try data.object("type"))
      }
      let metadata = try success.optionalObject("metadata").map {
        metadata throws(PrinterError) in
        (required: try metadata.bool("required"), type: try TypeNode(try metadata.object("type")))
      }
      self.success = .envelope(data: data, metadata: metadata)
    case "event-stream":
      self.success = .eventStream(event: try TypeNode(try success.object("event")))
    case "binary":
      self.success = .binary(
        mediaTypes: try success.array("mediaTypes").map { item throws(PrinterError) in
          try item.stringValue()
        }
      )
    default:
      throw PrinterError(
        "\(success.path): a success of kind `\(kind)`, which this printer does not know")
    }
    successResponses = try SuccessResponse.all(in: success)
    documents = try (success.optionalArray("documents") ?? []).map {
      item throws(PrinterError) in
      Document(
        mediaType: try item.string("mediaType"),
        type: try TypeNode(try item.object("type"))
      )
    }
    errors = try (reader.optionalArray("errors") ?? []).map { item throws(PrinterError) in
      ErrorStatus(
        status: try item.integer("status"),
        metadata: try item.optionalObject("metadata").map { metadata throws(PrinterError) in
          (required: try metadata.bool("required"), type: try TypeNode(try metadata.object("type")))
        }
      )
    }
    tasks = try (reader.optionalArray("tasks") ?? []).map { item throws(PrinterError) in
      try item.stringValue()
    }
    summary = try reader.optionalString("summary")
    description = try reader.optionalString("description")
    deprecated = try reader.optionalBool("deprecated") ?? false
  }
}

// MARK: - The Data API

/// DataSurface is the Data API.
package struct DataSurface: Sendable {
  package let origin: String
  package let endpoint: String
  package let operations: [DataOperationModel]
  package let objects: [DataObject]
  package let inputs: [DataObject]
  package let enums: [DataEnum]
  package let scalars: [DataScalar]

  init(_ reader: Reader) throws(PrinterError) {
    origin = try reader.string("origin")
    endpoint = try reader.string("endpoint")
    operations = try reader.array("operations").map { item throws(PrinterError) in
      try DataOperationModel(item)
    }
    objects = try reader.array("objects").map { item throws(PrinterError) in
      try DataObject(item, isInput: false)
    }
    inputs = try reader.array("inputs").map { item throws(PrinterError) in
      try DataObject(item, isInput: true)
    }
    enums = try reader.array("enums").map { item throws(PrinterError) in try DataEnum(item) }
    scalars = try reader.array("scalars").map { item throws(PrinterError) in
      try DataScalar(item)
    }
  }
}

/// DataType is a GraphQL type reference: a named type or a list, each nullable or not.
package struct DataType: Sendable {
  package indirect enum Kind: Sendable {
    case named(String)
    case list(DataType)
  }

  package let kind: Kind
  package let nullable: Bool

  init(_ reader: Reader) throws(PrinterError) {
    nullable = try reader.optionalBool("nullable") ?? false
    let kind = try reader.string("kind")
    switch kind {
    case "ref":
      self.kind = .named(try reader.string("name"))
    case "array":
      self.kind = .list(try DataType(try reader.object("items")))
    default:
      throw PrinterError(
        "\(reader.path): a Data API type of kind `\(kind)`, which this printer does not know")
    }
  }
}

/// DataField is one field of a Data API object or input.
package struct DataField: Sendable {
  package let name: String
  package let type: DataType
  /// required is what a caller must send: true only on an input, for a non-null field with no
  /// default.
  package let required: Bool
  package let description: String?
  package let deprecated: Bool
}

/// DataObject is a Data API object type or input type.
package struct DataObject: Sendable {
  package let name: String
  package let description: String?
  package let fields: [DataField]

  init(_ reader: Reader, isInput: Bool) throws(PrinterError) {
    name = try reader.string("name")
    description = try reader.optionalString("description")
    fields = try reader.array("fields").map { item throws(PrinterError) in
      DataField(
        name: try item.string("name"),
        type: try DataType(try item.object("type")),
        required: isInput ? try item.bool("required") : false,
        description: try item.optionalString("description"),
        deprecated: try item.optionalBool("deprecated") ?? false
      )
    }
  }
}

/// DataEnum is a Data API enum, whose wire value is each member's name.
package struct DataEnum: Sendable {
  package struct Member: Sendable {
    package let name: String
    package let description: String?
    package let deprecated: Bool
  }

  package let name: String
  package let description: String?
  package let members: [Member]

  init(_ reader: Reader) throws(PrinterError) {
    name = try reader.string("name")
    description = try reader.optionalString("description")
    members = try reader.array("members").map { item throws(PrinterError) in
      Member(
        name: try item.string("name"),
        description: try item.optionalString("description"),
        deprecated: try item.optionalBool("deprecated") ?? false
      )
    }
  }
}

/// DataScalar is a Data API scalar: one of GraphQL's own, or one the Data API declares with
/// the wire form its value travels in.
package struct DataScalar: Sendable {
  /// Wire is the form a declared scalar's value travels in.
  package enum Wire: Sendable {
    /// string is a string, in the format the bundle spells.
    case string(format: String?)
    /// geojson is one of RFC 7946's shapes, named by its geometry.
    case geojson(geometry: String)
  }

  package let name: String
  package let builtin: Bool
  /// wire is the form a declared scalar travels in, and nil for one of GraphQL's own.
  package let wire: Wire?

  init(_ reader: Reader) throws(PrinterError) {
    name = try reader.string("name")
    builtin = try reader.optionalBool("builtin") ?? false
    if let wire = try reader.optionalObject("wire") {
      let kind = try wire.string("kind")
      switch kind {
      case "string":
        self.wire = .string(format: try wire.optionalString("format"))
      case "geojson":
        self.wire = .geojson(geometry: try wire.string("geometry"))
      default:
        throw PrinterError(
          "\(wire.path): a scalar's wire of kind `\(kind)`, which this printer does not know")
      }
    } else {
      wire = nil
    }
    guard builtin != (wire != nil) else {
      throw PrinterError("\(reader.path): a scalar must be GraphQL's own or name its wire form")
    }
  }
}

/// DataOperationModel is one Data API operation: its input, its result, and its field tree.
package struct DataOperationModel: Sendable {
  /// Field is one field of the tree, with its own fields where it is an object.
  package struct Field: Sendable {
    package let name: String
    package let fields: [Field]?
  }

  package let name: String
  package let input: String
  package let inputType: String
  package let resultType: String
  /// scopes is the publishable-key scopes any one of which reaches the operation.
  package let scopes: [String]
  /// timeoutMs is the budget the SDL's introduction states once for every operation.
  package let timeoutMs: Int
  /// credentials is what the operation declares about the credentials it takes, as a REST
  /// operation declares it.
  package let credentials: Operation.Credentials
  /// successResponses is every status a success arrives with and the headers each declares.
  package let successResponses: [Operation.SuccessResponse]
  package let selection: [Field]
  package let document: String
  package let description: String?

  init(_ reader: Reader) throws(PrinterError) {
    name = try reader.string("name")
    input = try reader.string("input")
    inputType = try reader.string("inputType")
    resultType = try reader.string("resultType")
    scopes = try reader.array("scopes").map { item throws(PrinterError) in try item.stringValue() }
    timeoutMs = try reader.integer("timeoutMs")
    credentials = try Operation.Credentials(try reader.object("credentials"))
    successResponses = try Operation.SuccessResponse.all(in: try reader.object("success"))
    selection = try Self.tree(try reader.array("selection"))
    document = try reader.string("document")
    description = try reader.optionalString("description")
  }

  /// isQuery is true where the operation's document is a GraphQL query, which `sdk/SPEC.md` §1
  /// reads as a read whatever method it travels over: the document's first word is its kind.
  package var isQuery: Bool {
    document.drop { $0 == " " || $0 == "\n" || $0 == "\t" }
      .prefix { ("a"..."z").contains($0) } == "query"
  }

  private static func tree(_ items: [Reader]) throws(PrinterError) -> [Field] {
    try items.map { item throws(PrinterError) in
      Field(
        name: try item.string("name"),
        fields: try item.optionalArray("fields").map { fields throws(PrinterError) in
          try tree(fields)
        }
      )
    }
  }
}

// MARK: - Reading

/// Reader reads one JSON value of the model, naming where it is in every refusal.
struct Reader: Sendable {
  let json: OrderedJSON
  let path: String

  init(_ json: OrderedJSON, at path: String) {
    self.json = json
    self.path = path
  }

  private func value(_ key: String) throws(PrinterError) -> OrderedJSON {
    guard let value = json[key] else {
      throw PrinterError("\(path): no `\(key)`")
    }
    return value
  }

  func string(_ key: String) throws(PrinterError) -> String {
    guard let text = try value(key).stringValue else {
      throw PrinterError("\(path).\(key): not a string")
    }
    return text
  }

  func optionalString(_ key: String) throws(PrinterError) -> String? {
    guard let value = json[key], !value.isNull else { return nil }
    guard let text = value.stringValue else {
      throw PrinterError("\(path).\(key): not a string")
    }
    return text
  }

  func bool(_ key: String) throws(PrinterError) -> Bool {
    guard let flag = try value(key).boolValue else {
      throw PrinterError("\(path).\(key): not a boolean")
    }
    return flag
  }

  func optionalBool(_ key: String) throws(PrinterError) -> Bool? {
    guard let value = json[key] else { return nil }
    guard let flag = value.boolValue else {
      throw PrinterError("\(path).\(key): not a boolean")
    }
    return flag
  }

  func optionalNumber(_ key: String) throws(PrinterError) -> Double? {
    guard let value = json[key] else { return nil }
    guard let number = value.numberValue else {
      throw PrinterError("\(path).\(key): not a number")
    }
    return number
  }

  func optionalInteger(_ key: String) throws(PrinterError) -> Int? {
    guard let value = json[key], !value.isNull else { return nil }
    return try integer(key)
  }

  func integer(_ key: String) throws(PrinterError) -> Int {
    guard let number = try value(key).numberValue, let integer = Int(exactly: number) else {
      throw PrinterError("\(path).\(key): not an integer")
    }
    return integer
  }

  func object(_ key: String) throws(PrinterError) -> Reader {
    let value = try value(key)
    guard value.members != nil else {
      throw PrinterError("\(path).\(key): not an object")
    }
    return Reader(value, at: "\(path).\(key)")
  }

  func optionalObject(_ key: String) throws(PrinterError) -> Reader? {
    guard json[key] != nil else { return nil }
    return try object(key)
  }

  func array(_ key: String) throws(PrinterError) -> [Reader] {
    guard let elements = try value(key).elements else {
      throw PrinterError("\(path).\(key): not an array")
    }
    return elements.enumerated().map { Reader($1, at: "\(path).\(key)[\($0)]") }
  }

  func optionalArray(_ key: String) throws(PrinterError) -> [Reader]? {
    guard json[key] != nil else { return nil }
    return try array(key)
  }

  func stringValue() throws(PrinterError) -> String {
    guard let text = json.stringValue else {
      throw PrinterError("\(path): not a string")
    }
    return text
  }
}
