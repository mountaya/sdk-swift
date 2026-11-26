import Foundation

/// OperationPrinter prints every operation a client emits: the accessors and their methods, a
/// walk beside each paged one, the query and body types the methods take, the facts table, the
/// Data API's field trees, and the routes a map renderer fetches on its own as URL templates.
struct OperationPrinter {
  let printer: Printer
  /// rest is the core's REST namespace, and admin the admin unit's, which a group of the admin
  /// unit prints its operations' types in.
  let rest: Namespace
  let admin: Namespace
  let tiles: Namespace

  /// Names a method's own parameters and locals take, which no path or header parameter may.
  static let reservedParameters: Set<String> = [
    "body", "idempotencyKey", "ifMatch", "input", "maxPages", "options", "page", "pageSize",
    "query", "request", "select", "sender",
  ]

  func printAll() throws(PrinterError) {
    var groups: [String: [String: [Operation]]] = [:]
    var groupOrder: [String] = []
    // Every operation of a group is one unit's, which `Printer.checkUnits` has held.
    var units: [String: ClientUnit] = [:]
    for operation in printer.model.rest.operations {
      guard let namespace = operation.namespace else {
        throw PrinterError("rest.\(operation.operationId): no `x-sdk-namespace`")
      }
      let segments = namespace.split(separator: ".").map(String.init)
      guard segments.count == 2 else {
        throw PrinterError(
          "rest.\(operation.operationId): a namespace that is not `group.resource`")
      }
      if groups[segments[0]] == nil {
        groupOrder.append(segments[0])
      }
      groups[segments[0], default: [:]][segments[1], default: []].append(operation)
      units[segments[0]] = operation.unit
    }

    for group in groupOrder.sorted() {
      let resources = groups[group] ?? [:]
      let space = units[group] == .admin ? admin : rest
      try printGroup(group, resources: resources.keys.sorted(), unit: space.unit)
      for resource in resources.keys.sorted() {
        try printResource(
          group: group, resource: resource, operations: resources[resource] ?? [], space: space)
      }
    }
    var facts = try printer.model.rest.operations.filter { $0.unit == .core }.map {
      operation throws(PrinterError) in try FactsEntry(operation, surface: "rest")
    }
    let adminFacts = try printer.model.rest.operations.filter { $0.unit == .admin }.map {
      operation throws(PrinterError) in try FactsEntry(operation, surface: "rest")
    }
    try printTiles()
    facts += try printer.model.tiles.operations.map { operation throws(PrinterError) in
      try FactsEntry(operation, surface: "tiles")
    }
    try printData()
    facts += printer.model.data.operations.map {
      FactsEntry(data: $0, endpoint: printer.model.data.endpoint)
    }
    try printFacts(facts, admin: adminFacts)
    try checkDeclaredTypes(printer.model.rest, space: rest)
    try checkDeclaredTypes(printer.model.tiles, space: tiles)
    try printTemplates(printer.model.rest.templates, named: "RestTemplates", surface: "REST API")
    try printTemplates(printer.model.tiles.templates, named: "TileTemplates", surface: "Tile API")

    try printer.printInline(rest)
    try printer.printInline(admin)
    try printer.printInline(tiles)
  }

  /// checkDeclaredTypes resolves every type an operation declares that no method prints, so a
  /// name that names no component is refused rather than read past: the headers a success
  /// declares, the metadata an error status adds, and the documents a template's route answers.
  /// Nothing is printed for them, and an inline type among them is checked, never registered.
  private func checkDeclaredTypes(_ surface: Surface, space: Namespace) throws(PrinterError) {
    for operation in surface.operations + surface.templates {
      let site = "\(space.name).\(operation.operationId)"
      for response in operation.successResponses {
        for header in response.headers {
          try resolves(header.type, in: space, at: site)
        }
      }
      for error in operation.errors {
        if let metadata = error.metadata {
          try resolves(metadata.type, in: space, at: site)
        }
      }
      for document in operation.documents {
        try resolves(document.type, in: space, at: site)
      }
    }
  }

  /// resolves refuses a type that names a component its surface does not hold, anywhere inside
  /// it.
  private func resolves(_ node: TypeNode, in space: Namespace, at site: String)
    throws(PrinterError)
  {
    switch node.kind {
    case .ref(let name):
      guard space.schemas[name] != nil else {
        throw PrinterError("\(site): `\(name)` names no component")
      }
    case .array(let items):
      try resolves(items, in: space, at: site)
    case .map(let values, let keys):
      try resolves(values, in: space, at: site)
      if let keys {
        try resolves(keys, in: space, at: site)
      }
    case .object(let object):
      for property in object.properties {
        try resolves(property.type, in: space, at: site)
      }
    case .union(_, let members):
      for member in members {
        try resolves(member, in: space, at: site)
      }
    case .string, .integer, .number, .boolean, .null, .any:
      break
    }
  }

  // MARK: - Accessors

  /// printGroup prints a group's accessor on the client and its type, in the group's unit: the
  /// admin unit declares its group on the core's client in an extension, so importing it is the
  /// whole of what a call into it asks, and the core's client declares none of its own.
  private func printGroup(_ group: String, resources: [String], unit: ClientUnit)
    throws(PrinterError)
  {
    let type = SwiftText.upperFirst(group)
    try printer.emit("Mountaya/Mountaya.\(type).swift", unit: unit) { writer throws(PrinterError) in
      try writer.block("extension Mountaya {") { writer throws(PrinterError) in
        writer.doc(
          "\(group) is every operation of the contract's `\(group)` group."
            + (unit == .core
              ? ""
              : " The client's \(unit.rawValue) unit declares it, so importing `\(unit.module)` is "
                + "the whole of what a call into it asks."))
        try writer.block("public var \(SwiftText.identifier(group)): \(type) {") {
          writer throws(PrinterError) in
          writer.line("\(type)(sender: sender)")
        }
        writer.line()
        writer.doc("\(type) is the `\(group)` group's resources, one accessor to a resource.")
        try writer.block("public struct \(type): Sendable {") { writer throws(PrinterError) in
          writer.line("let sender: any OperationSending")
          for resource in resources {
            let resourceType = SwiftText.upperFirst(resource)
            writer.line()
            writer.doc("\(resource) is every operation of `\(group).\(resource)`.")
            try writer.block("public var \(SwiftText.identifier(resource)): \(resourceType) {") {
              writer throws(PrinterError) in
              writer.line("\(resourceType)(sender: sender)")
            }
          }
        }
      }
    }
  }

  private func printResource(
    group: String, resource: String, operations: [Operation], space: Namespace
  ) throws(PrinterError) {
    let groupType = SwiftText.upperFirst(group)
    let type = SwiftText.upperFirst(resource)
    try printer.emit("Mountaya/Mountaya.\(groupType).\(type).swift", unit: space.unit) {
      writer throws(PrinterError) in
      try writer.block("extension Mountaya.\(groupType) {") { writer throws(PrinterError) in
        writer.doc(
          "\(type) is every operation of `\(group).\(resource)`, one method to an operation.")
        try writer.block("public struct \(type): Sendable {") { writer throws(PrinterError) in
          writer.line("let sender: any OperationSending")
          try methods(&writer, operations: operations, space: space)
        }
      }
    }
    for operation in operations {
      try printParameterTypes(operation, space: space)
    }
  }

  private func printTiles() throws(PrinterError) {
    try printer.emit("Mountaya/Mountaya.Tiles.swift", unit: .core) { writer throws(PrinterError) in
      try writer.block("extension Mountaya {") { writer throws(PrinterError) in
        writer.doc("tiles is every operation of the Tile API a caller awaits.")
        try writer.block("public var tiles: Tiles {") { writer throws(PrinterError) in
          writer.line("Tiles(sender: sender)")
        }
        writer.line()
        writer.doc(
          "Tiles is the Tile API's operations, one method to an operation. The tile routes "
            + "themselves are URL templates a map fetches, and no method here binds one."
        )
        try writer.block("public struct Tiles: Sendable {") { writer throws(PrinterError) in
          writer.line("let sender: any OperationSending")
          try methods(&writer, operations: printer.model.tiles.operations, space: tiles)
        }
      }
    }
    for operation in printer.model.tiles.operations {
      try printParameterTypes(operation, space: tiles)
    }
  }

  // MARK: - Methods

  /// methods writes an accessor's methods, one to an operation, each paged one followed by its
  /// walk, refusing a walk's name another operation of the accessor holds.
  private func methods(_ writer: inout SourceWriter, operations: [Operation], space: Namespace)
    throws(PrinterError)
  {
    let names = Set(operations.map(\.operationId))
    for operation in operations {
      writer.line()
      try method(&writer, operation: operation, space: space)
      guard operation.pagination != nil else { continue }
      let name = walkName(operation)
      guard !names.contains(name) else {
        throw PrinterError(
          "\(space.name).\(name): the walk \(operation.operationId) synthesizes is an operation's name"
        )
      }
      writer.line()
      try walk(&writer, operation: operation, space: space)
    }
  }

  /// method writes one operation's method.
  private func method(_ writer: inout SourceWriter, operation: Operation, space: Namespace)
    throws(PrinterError)
  {
    let site = "\(space.name).\(operation.operationId)"
    var doc = [operation.summary, operation.description].compactMap { $0 }
      .joined(separator: "\n\n")
    if doc.isEmpty {
      doc = "The contract's `\(operation.operationId)`."
    }
    if operation.idempotencyKey {
      doc +=
        "\n\n`idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the "
        + "caller's, which makes two of its calls one write, or one the client draws once."
    }
    if operation.conditional {
      doc +=
        "\n\n`ifMatch` is the `etag` the caller read the resource under, or `\"*\"`, sent as "
        + "`If-Match` exactly as given, and nothing is sent where it is `nil`."
    }
    writer.doc(doc)
    if operation.deprecated {
      Layout.available(
        &writer, deprecated: Layout.deprecation(operation.summary ?? operation.description))
    }

    var parameters: [String] = []
    var path: [String] = []
    for parameter in try pathParameters(operation) {
      let shape = try printer.shape(parameter.type, in: space, usage: ["request"])
      guard let text = shape.text, !shape.isList else {
        throw PrinterError("\(site): the path parameter `\(parameter.name)` has no path spelling")
      }
      let name = SwiftText.identifier(parameter.name)
      parameters.append("\(name): \(shape.swift)")
      path.append("\(SwiftText.literal(parameter.name)): \(text(name))")
    }
    if !operation.queryParameters.isEmpty {
      let type = "\(space.name).\(queryType(operation))"
      let required = operation.queryParameters.contains(where: \.required)
      parameters.append(required ? "query: \(type)" : "query: \(type) = .init()")
    }
    let body = try bodyParameter(operation, space: space)
    if let body {
      parameters.append(
        operation.bodyRequired ? "body: \(body.type)" : "body: \(optionalType(body.type)) = nil"
      )
    }
    if operation.idempotencyKey {
      parameters.append("idempotencyKey: String? = nil")
    }
    if operation.conditional {
      parameters.append("ifMatch: String? = nil")
    }
    var headers: [String] = []
    for parameter in operation.headerParameters {
      let shape = try printer.shape(parameter.type, in: space, usage: ["request"])
      guard shape.swift == "String" else {
        throw PrinterError("\(site): the header `\(parameter.name)` is not a string")
      }
      let name = SwiftText.identifier(parameter.name)
      parameters.append(parameter.required ? "\(name): String" : "\(name): String? = nil")
      headers.append("\(SwiftText.literal(parameter.name)): \(name)")
    }
    parameters.append("options: RequestOptions = RequestOptions()")

    let (returns, callee) = try answer(operation, space: space)
    // An event stream opens as its first frame is asked for, so its method awaits nothing and
    // throws only what it refuses before any request (SPEC.md section 3).
    let isStream = callee == "events"
    writer.line("public func \(SwiftText.identifier(operation.operationId))(")
    for (position, parameter) in parameters.enumerated() {
      writer.line("  " + parameter + (position == parameters.count - 1 ? "" : ","))
    }
    closing(&writer, effects: isStream ? "throws" : "async throws", returns: returns)

    try writer.nested { writer throws(PrinterError) in
      var arguments = ["facts: .\(SwiftText.identifier(operation.operationId))"]
      if !path.isEmpty {
        arguments.append("pathParameters: [\(path.joined(separator: ", "))]")
      }
      if !operation.queryParameters.isEmpty {
        arguments.append("query: query.items")
      }
      if !headers.isEmpty {
        arguments.append("headers: [\(headers.joined(separator: ", "))]")
      }
      if let body {
        arguments.append("body: \(operation.bodyRequired ? body.payload : body.optionalPayload)")
      }
      if operation.idempotencyKey {
        arguments.append("idempotencyKey: idempotencyKey")
      }
      if operation.conditional {
        arguments.append("ifMatch: ifMatch")
      }
      request(&writer, arguments: arguments)
      writer.line(
        "return try \(isStream ? "" : "await ")sender.\(callee)(request, options: options)")
    }
    writer.line("}")
  }

  /// walkName is the name of the walk beside a paged operation's method: `walk` before the
  /// operation's name, its first letter raised, `walkGetItineraries`.
  private func walkName(_ operation: Operation) -> String {
    "walk" + SwiftText.upperFirst(operation.operationId)
  }

  /// walk writes the walk beside a paged operation's method: the same path parameters and typed
  /// query, a page size defaulting to the one the operation's `limit` states, a ceiling on
  /// requests and the call's options, answering the listing's rows, as the operation types them,
  /// through a `PageWalk` over the method (`transport.pagination.walk`).
  private func walk(_ writer: inout SourceWriter, operation: Operation, space: Namespace)
    throws(PrinterError)
  {
    let site = "\(space.name).\(operation.operationId)"
    guard let pageSize = operation.pagination?.defaultLimit else {
      throw PrinterError("\(site): it pages by cursor and its `limit` states no default")
    }
    guard case .envelope(let data?, let metadata?) = operation.success,
      case .array(let items) = data.kind, !data.nullable, !items.nullable, metadata.required,
      !metadata.type.nullable
    else {
      throw PrinterError("\(site): it pages by cursor and answers no list beside its metadata")
    }
    let row = try printer.shape(items, in: space, usage: ["response"]).swift
    let query = "\(space.name).\(queryType(operation))"
    let method = SwiftText.identifier(operation.operationId)

    writer.doc(
      "\(walkName(operation)) walks the listing `\(operation.operationId)` answers, one row at a "
        + "time, requesting a page only as the rows before it are read "
        + "(`transport.pagination.walk`).\n\n"
        + "Every request sends `query`, its filters and `sort` included, with its `limit` "
        + "replaced by `pageSize`, from 1 to 100, and its `cursor` by the one the walk has "
        + "reached, starting from `query`'s own, so a walk resumes where an earlier one stopped. "
        + "It follows every page for as long as a `next_cursor` names one, an empty page "
        + "included, and stops at a null `next_cursor`, at `maxPages` requests, which raises "
        + "nothing, or at a cursor it has already sent, which raises the base `APIError`. A "
        + "cancelled task requests no further page.\n\n"
        + "`options` overrides what every request of the walk may of the client's "
        + "configuration. It throws `ConfigurationError` for a `pageSize` or a `maxPages` out of "
        + "its range, before any request."
    )
    if operation.deprecated {
      Layout.available(
        &writer, deprecated: Layout.deprecation(operation.summary ?? operation.description))
    }
    var parameters: [String] = []
    var arguments: [String] = []
    for parameter in try pathParameters(operation) {
      let shape = try printer.shape(parameter.type, in: space, usage: ["request"])
      let name = SwiftText.identifier(parameter.name)
      parameters.append("\(name): \(shape.swift)")
      arguments.append("\(name): \(name)")
    }
    let required = operation.queryParameters.contains(where: \.required)
    parameters.append(required ? "query: \(query)" : "query: \(query) = .init()")
    parameters.append("pageSize: Int = \(pageSize)")
    parameters.append("maxPages: Int? = nil")
    parameters.append("options: RequestOptions = RequestOptions()")
    arguments += ["query: page", "options: options"]

    writer.line("public func \(walkName(operation))(")
    for (position, parameter) in parameters.enumerated() {
      writer.line("  " + parameter + (position == parameters.count - 1 ? "" : ","))
    }
    closing(&writer, effects: "throws(MountayaError)", returns: "PageWalk<\(query), \(row)>")
    let opening = "try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in"
    try writer.nested { writer throws(PrinterError) in
      try writer.block(opening) { writer throws(PrinterError) in
        writer.call(prefix: "try await ", callee: method, arguments: arguments)
      }
    }
    writer.line("}")
  }

  /// closing writes `) async throws -> T {`, or the `effects` given in place of `async throws`, as
  /// the formatter lays it out, breaking a generic return type inside its angle brackets where
  /// the line does not fit.
  private func closing(
    _ writer: inout SourceWriter, effects: String = "async throws", returns: String
  ) {
    let whole = ") \(effects) -> \(returns) {"
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    guard let open = returns.firstIndex(of: "<"), returns.hasSuffix(">") else {
      writer.line(") \(effects)")
      writer.line("  -> \(returns)")
      writer.line("{")
      return
    }
    let head = returns[...open]
    let inner = String(
      returns[returns.index(after: open)..<returns.index(before: returns.endIndex)])
    writer.line(") \(effects) -> \(head)")
    if writer.fits(inner, extra: 2) {
      writer.line("  " + inner)
    } else {
      let arguments = splitTopLevel(inner)
      for (position, argument) in arguments.enumerated() {
        writer.line("  " + argument + (position == arguments.count - 1 ? "" : ","))
      }
    }
    writer.line("> {")
  }

  /// request writes the `OperationRequest` a method builds, one argument to a line, a literal
  /// too long for its line broken one entry to a line.
  private func request(_ writer: inout SourceWriter, arguments: [String]) {
    if arguments.count == 1 {
      writer.call(prefix: "let request = ", callee: "OperationRequest", arguments: arguments)
      return
    }
    writer.line("let request = OperationRequest(")
    for (position, argument) in arguments.enumerated() {
      let isLast = position == arguments.count - 1
      // The formatter measures the last argument with the parenthesis that closes the call.
      let measured = argument + (isLast ? ")" : ",")
      guard !writer.fits(measured, extra: 2), argument.hasSuffix("]"),
        let open = argument.firstIndex(of: "[")
      else {
        writer.line("  " + argument + (isLast ? "" : ","))
        continue
      }
      let label = argument[..<open]
      let inner = String(
        argument[argument.index(after: open)..<argument.index(before: argument.endIndex)]
      )
      let entries = splitTopLevel(inner)
      writer.line("  \(label)[")
      var current = ""
      for (index, entry) in entries.enumerated() {
        let piece = entry + (index < entries.count - 1 || entries.count > 1 ? "," : "")
        let candidate = current.isEmpty ? piece : current + " " + piece
        if current.isEmpty || writer.fits(candidate, extra: 4) {
          current = candidate
        } else {
          writer.line("    " + current)
          current = piece
        }
      }
      writer.line("    " + current)
      writer.line("  ]" + (isLast ? "" : ","))
    }
    writer.line(")")
  }

  /// splitTopLevel splits a comma-separated list at the commas outside any brackets.
  private func splitTopLevel(_ text: String) -> [String] {
    var parts: [String] = []
    var depth = 0
    var current = ""
    var inString = false
    for character in text {
      if character == "\"" {
        inString.toggle()
      }
      if !inString {
        if "[(<".contains(character) { depth += 1 }
        if "])>".contains(character) { depth -= 1 }
      }
      if character == ",", depth == 0, !inString {
        parts.append(current.trimmingCharacters(in: .whitespaces))
        current = ""
      } else {
        current.append(character)
      }
    }
    parts.append(current.trimmingCharacters(in: .whitespaces))
    return parts
  }

  private func pathParameters(_ operation: Operation) throws(PrinterError) -> [Parameter] {
    var placed: [(position: String.Index, parameter: Parameter)] = []
    for parameter in operation.pathParameters {
      guard !Self.reservedParameters.contains(parameter.name) else {
        throw PrinterError(
          "\(operation.operationId): a path parameter named `\(parameter.name)`, which the method uses"
        )
      }
      guard let range = operation.path.range(of: "{\(parameter.name)}") else {
        throw PrinterError(
          "\(operation.operationId): `\(parameter.name)` is not in the path `\(operation.path)`"
        )
      }
      placed.append((range.lowerBound, parameter))
    }
    return placed.sorted { $0.position < $1.position }.map(\.parameter)
  }

  /// answer is what a method returns and the seam's requirement that sends it.
  private func answer(_ operation: Operation, space: Namespace) throws(PrinterError)
    -> (returns: String, callee: String)
  {
    switch operation.success {
    case .envelope(let data, let metadata):
      let value = try data.map { data throws(PrinterError) in
        let shape = try printer.shape(data, in: space, usage: ["response"])
        return data.nullable ? optionalType(shape.swift) : shape.swift
      }
      let declared = try metadata.map { metadata throws(PrinterError) in
        let shape = try printer.shape(metadata.type, in: space, usage: ["response"])
        return metadata.required && !metadata.type.nullable
          ? shape.swift : optionalType(shape.swift)
      }
      return (
        "Response<\(value ?? "JSONValue"), \(declared ?? "[String: JSONValue]?")>",
        "envelope"
      )
    case .eventStream(let event):
      let shape = try printer.shape(event, in: space, usage: ["response"])
      return ("EventStream<\(shape.swift)>", "events")
    case .binary:
      return ("BinaryResponse", "binary")
    }
  }

  // MARK: - Parameter types

  /// BodyParameter is the type a method's `body:` takes and how it becomes the request's.
  struct BodyParameter {
    let type: String
    /// payload is the request's body, from a required `body`.
    let payload: String
    /// optionalPayload is the request's body, from an optional `body`.
    let optionalPayload: String
  }

  private func queryType(_ operation: Operation) -> String {
    SwiftText.upperFirst(operation.operationId) + "Query"
  }

  private func bodyType(_ operation: Operation) -> String {
    SwiftText.upperFirst(operation.operationId) + "Body"
  }

  private func bodyParameter(_ operation: Operation, space: Namespace) throws(PrinterError)
    -> BodyParameter?
  {
    guard !operation.bodyContent.isEmpty else { return nil }
    if operation.bodyContent.count == 1, let content = operation.bodyContent.first {
      let type = try bodyContentType(content, operation: operation, space: space)
      switch content.mediaType {
      case "application/json":
        return BodyParameter(
          type: type,
          payload: ".json(body)",
          optionalPayload: "body.map { OperationBody.json($0) } ?? .none"
        )
      case "multipart/form-data":
        return BodyParameter(
          type: type,
          payload: ".multipart(body.parts)",
          optionalPayload: "body.map { OperationBody.multipart($0.parts) } ?? .none"
        )
      default:
        throw PrinterError("\(operation.operationId): a body as `\(content.mediaType)`")
      }
    }
    return BodyParameter(
      type: "\(space.name).\(bodyType(operation))",
      payload: "body.payload",
      optionalPayload: "body.map(\\.payload) ?? .none"
    )
  }

  /// bodyContentType is the Swift type one media type of a body is, registering an inline form.
  private func bodyContentType(
    _ content: Operation.BodyContent,
    operation: Operation,
    space: Namespace
  ) throws(PrinterError) -> String {
    if content.mediaType == "multipart/form-data" {
      guard case .object(let form) = content.type.kind else {
        throw PrinterError(
          "\(operation.operationId): a `multipart/form-data` body that is not written inline"
        )
      }
      var encoding: [String: String] = [:]
      for entry in content.encoding {
        guard encoding.updateValue(entry.contentType, forKey: entry.property) == nil else {
          throw PrinterError(
            "\(operation.operationId): the form's encoding names `\(entry.property)` twice")
        }
      }
      try printer.register(
        .object(form, usage: ["request"], form: encoding),
        named: form.name,
        in: space
      )
      return "\(space.name).\(form.name)"
    }
    return try printer.shape(content.type, in: space, usage: ["request"]).swift
  }

  /// printParameterTypes prints the query type and the body type an operation synthesizes.
  private func printParameterTypes(_ operation: Operation, space: Namespace) throws(PrinterError) {
    if !operation.queryParameters.isEmpty {
      let name = queryType(operation)
      try synthesized(name, in: space, operation: operation)
      let types = TypePrinter(printer: printer, space: space)
      let members = try operation.queryParameters.map { parameter throws(PrinterError) in
        let member = try types.member(
          Property(parameter: parameter),
          usage: ["request"],
          threeStates: false
        )
        return member
      }
      try printer.emit("\(space.name)/\(space.name).\(name).swift", unit: space.unit) {
        writer throws(PrinterError) in
        try writer.block("extension \(space.name) {") { writer throws(PrinterError) in
          try Layout.object(
            &writer,
            name: name,
            doc: "\(name) is the query of `\(operation.operationId)`, one property to a parameter.",
            members: members,
            style: .query,
            conformingTo: operation.pagination == nil ? [] : ["PagedQuery"]
          )
        }
      }
    }
    if operation.bodyContent.count > 1 {
      let name = bodyType(operation)
      try synthesized(name, in: space, operation: operation)
      var cases: [(name: String, type: String, mediaType: String)] = []
      for content in operation.bodyContent {
        let label: String
        switch content.mediaType {
        case "application/json": label = "json"
        case "multipart/form-data": label = "multipart"
        default: throw PrinterError("\(operation.operationId): a body as `\(content.mediaType)`")
        }
        cases.append(
          (
            label, try bodyContentType(content, operation: operation, space: space),
            content.mediaType
          )
        )
      }
      try printer.emit("\(space.name)/\(space.name).\(name).swift", unit: space.unit) {
        writer throws(PrinterError) in
        try writer.block("extension \(space.name) {") { writer throws(PrinterError) in
          writer.doc(
            "\(name) is the body of `\(operation.operationId)`, which the contract takes in more "
              + "than one media type: one case to a media type, in the contract's order. "
              + Layout.nonexhaustiveNote(
                "A media type the contract adds is a case of the build made after it")
          )
          Layout.nonexhaustive(&writer)
          try writer.block("public enum \(name): Sendable, Hashable {") {
            writer throws(PrinterError) in
            for item in cases {
              writer.doc("\(item.name) is the body sent as `\(item.mediaType)`.")
              writer.call(prefix: "case ", callee: item.name, arguments: [item.type])
            }
            writer.line()
            writer.doc("payload is the body as the request carries it.")
            try writer.block("var payload: OperationBody {") { writer throws(PrinterError) in
              writer.line("switch self {")
              for item in cases {
                writer.line("case .\(item.name)(let value):")
                writer.line(item.name == "json" ? "  .json(value)" : "  .multipart(value.parts)")
              }
              writer.line("}")
            }
          }
        }
      }
    }
  }

  /// synthesized refuses a synthesized type name a component or an inline type already holds.
  private func synthesized(_ name: String, in space: Namespace, operation: Operation)
    throws(PrinterError)
  {
    if space.schemas[name] != nil || printer.inline[space.name]?[name] != nil {
      throw PrinterError(
        "\(space.name).\(name): the type \(operation.operationId) synthesizes is a component's name"
      )
    }
  }

  // MARK: - The Data API

  private func printData() throws(PrinterError) {
    let data = printer.model.data
    let names = try DataPrinter(printer: printer).names()
    try printer.emit("Mountaya/Mountaya.Data.swift", unit: .core) { writer throws(PrinterError) in
      try writer.block("extension Mountaya {") { writer throws(PrinterError) in
        writer.doc("data is every operation of the Data API.")
        try writer.block("public var data: Data {") { writer throws(PrinterError) in
          writer.line("Data(sender: sender)")
        }
        writer.line()
        writer.doc(
          "Data is the Data API's operations, one method to an operation. A `select` narrows the "
            + "document sent and never the type returned: a field left out is `nil` in the result."
        )
        try writer.block("public struct Data: Sendable {") { writer throws(PrinterError) in
          writer.line("let sender: any OperationSending")
          for operation in data.operations {
            guard names[operation.input] == .input, names[operation.resultType] == .object else {
              throw PrinterError("DataSchema.\(operation.name): an input or result that is no type")
            }
            writer.line()
            writer.doc(operation.description ?? "The contract's `\(operation.name)`.")
            writer.line("public func \(SwiftText.identifier(operation.name))(")
            writer.line("  input: DataSchema.\(operation.input),")
            writer.line("  select: FieldSelection? = nil,")
            writer.line("  options: RequestOptions = RequestOptions()")
            closing(&writer, returns: "DataSchema.\(operation.resultType)")
            writer.line("  try await sender.query(")
            writer.line("    .\(SwiftText.identifier(operation.name)),")
            writer.line("    facts: .\(SwiftText.identifier(operation.name)),")
            writer.line("    input: input,")
            writer.line("    select: select,")
            writer.line("    options: options")
            writer.line("  )")
            writer.line("}")
          }
        }
      }
    }

    try printer.emit("DataOperation.Trees.swift", unit: .core) { writer throws(PrinterError) in
      try writer.block("extension DataOperation {") { writer throws(PrinterError) in
        for (position, operation) in data.operations.enumerated() {
          if position > 0 {
            writer.line()
          }
          writer.doc(
            "\(operation.name) is the Data API's `\(operation.name)`, with every field of its "
              + "result in the schema's order, which is its full selection, and its budget."
          )
          writer.line("static let \(SwiftText.identifier(operation.name)) = DataOperation(")
          writer.line("  name: \(SwiftText.literal(operation.name)),")
          writer.line("  inputType: \(SwiftText.literal(operation.inputType)),")
          writer.line("  selection: [")
          try writer.nested { writer throws(PrinterError) in
            try writer.nested { writer throws(PrinterError) in
              tree(&writer, fields: operation.selection)
            }
          }
          writer.line("  ],")
          writer.line("  timeout: .milliseconds(\(operation.timeoutMs))")
          writer.line(")")
        }
      }
    }
  }

  /// tree writes a field tree as nested dictionary literals, a trailing comma after each entry
  /// of a literal holding more than one, as the formatter writes them.
  private func tree(_ writer: inout SourceWriter, fields: [DataOperationModel.Field]) {
    let comma = fields.count > 1 ? "," : ""
    for field in fields {
      let key = SwiftText.literal(field.name)
      if let children = field.fields {
        writer.line("\(key): [")
        writer.nestedLines { writer in
          tree(&writer, fields: children)
        }
        writer.line("]" + comma)
      } else {
        writer.line("\(key): true" + comma)
      }
    }
  }

  // MARK: - Facts

  /// printFacts prints each unit's facts: the core's REST, Tile and Data API operations, a table
  /// a surface, and the admin unit's operations, one table of its own, refusing two operations of
  /// one name across both.
  private func printFacts(_ facts: [FactsEntry], admin: [FactsEntry]) throws(PrinterError) {
    var seen: Set<String> = []
    for fact in facts + admin {
      guard seen.insert(fact.operationId).inserted else {
        throw PrinterError("two operations named `\(fact.operationId)`")
      }
    }
    for surface in ["rest", "tiles", "data"] {
      let list = "\(surface == "tiles" ? "tile" : surface)Operations"
      try printFacts(
        facts.filter { $0.surface == surface },
        file: SwiftText.upperFirst(surface),
        list: list,
        doc: surface == "rest"
          ? "\(list) is every operation of this surface but the admin unit's, which `MountayaAdmin` "
            + "prints as `adminOperations`, in the model's order."
          : "\(list) is every operation of this surface, in the model's order.",
        unit: .core
      )
    }
    try printFacts(
      admin,
      file: "Admin",
      list: "adminOperations",
      doc: "adminOperations is every operation of the admin unit, in the model's order.",
      unit: .admin
    )
  }

  /// printFacts prints one table of facts into a unit, the Data API's with the endpoint its
  /// operations are sent to.
  private func printFacts(
    _ entries: [FactsEntry], file: String, list: String, doc: String, unit: ClientUnit
  ) throws(PrinterError) {
    try printer.emit("OperationFacts/OperationFacts.\(file).swift", unit: unit) {
      writer throws(PrinterError) in
      try writer.block("extension OperationFacts {") { writer throws(PrinterError) in
        if file == "Data" {
          writer.doc(
            "dataEndpoint is the path every Data API operation is sent to, under the Data API's "
              + "origin, a call made by its declaration among them."
          )
          writer.line(
            "static let dataEndpoint = \(SwiftText.literal(printer.model.data.endpoint))")
          writer.line()
        }
        writer.doc(doc)
        guard !entries.isEmpty else {
          writer.line("static let \(list): [OperationFacts] = []")
          return
        }
        writer.line("static let \(list): [OperationFacts] = [")
        let comma = entries.count > 1 ? "," : ""
        for entry in entries {
          writer.line("  .\(SwiftText.identifier(entry.operationId))" + comma)
        }
        writer.line("]")
        for entry in entries {
          writer.line()
          entry.write(&writer)
        }
      }
    }
  }

  // MARK: - Templates

  /// printTemplates prints a surface's templates, the routes a map renderer fetches on its own,
  /// as the URL templates of a namespace named `name` at the module's scope: each its path, the
  /// path's parameters in the order it names them, the query's, and the media types it answers
  /// in, never a method a caller awaits (SPEC.md section 3). A surface with no template prints
  /// nothing.
  private func printTemplates(_ templates: [Operation], named name: String, surface: String)
    throws(PrinterError)
  {
    guard !templates.isEmpty else { return }
    var seen: Set<String> = []
    for template in templates {
      guard SwiftText.isPlain(template.operationId), seen.insert(template.operationId).inserted,
        template.operationId != "all"
      else {
        throw PrinterError("\(name).\(template.operationId): no name a template can take")
      }
    }
    try printer.emit("\(name).swift", unit: .core) { writer throws(PrinterError) in
      writer.doc(
        "\(name) is every route of the \(surface) a map renderer fetches on its own, the tiles "
          + "and the base map's style, TileJSON, sprite and glyph documents: URL templates, "
          + "resolved against the surface's origin, which no method binds."
      )
      try writer.block("public enum \(name) {") { writer throws(PrinterError) in
        writer.doc("all is every template, in the model's order.")
        writer.line("public static let all: [URLTemplate] = [")
        let comma = templates.count > 1 ? "," : ""
        for template in templates {
          writer.line("  \(SwiftText.identifier(template.operationId))" + comma)
        }
        writer.line("]")
        for template in templates {
          writer.line()
          try self.template(&writer, template: template, in: name)
        }
      }
    }
  }

  /// template writes one route's URL template.
  private func template(_ writer: inout SourceWriter, template: Operation, in name: String)
    throws(PrinterError)
  {
    let site = "\(name).\(template.operationId)"
    guard case .binary(let mediaTypes) = template.success else {
      throw PrinterError("\(site): a template that is not binary")
    }
    var placed: [(position: String.Index, name: String)] = []
    for parameter in template.pathParameters {
      guard let range = template.path.range(of: "{\(parameter.name)}") else {
        throw PrinterError("\(site): `\(parameter.name)` is not in the path `\(template.path)`")
      }
      placed.append((range.lowerBound, parameter.name))
    }
    let doc = [template.summary, template.description].compactMap { $0 }
      .joined(separator: "\n\n")
    writer.doc(doc.isEmpty ? "The contract's `\(template.operationId)`." : doc)
    writer.line("public static let \(SwiftText.identifier(template.operationId)) = URLTemplate(")
    writer.nestedLines { writer in
      writer.line("operationId: \(SwiftText.literal(template.operationId)),")
      writer.line("path: \(SwiftText.literal(template.path)),")
      Self.strings(
        &writer, label: "pathParameters",
        elements: placed.sorted { $0.position < $1.position }.map { SwiftText.literal($0.name) },
        last: false)
      Self.strings(
        &writer, label: "queryParameters",
        elements: template.queryParameters.map { SwiftText.literal($0.name) }, last: false)
      Self.strings(
        &writer, label: "mediaTypes", elements: mediaTypes.map(SwiftText.literal), last: true)
    }
    writer.line(")")
  }

  /// strings writes a labelled argument, a list of string literals, as the formatter lays an
  /// array literal out: on one line where it fits, and otherwise broken after the bracket, as
  /// many elements to a line as fit, each followed by a comma.
  private static func strings(
    _ writer: inout SourceWriter, label: String, elements: [String], last: Bool
  ) {
    let end = last ? "" : ","
    let whole = "\(label): [\(elements.joined(separator: ", "))]" + end
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    writer.line("\(label): [")
    var current = ""
    for element in elements {
      let piece = element + ","
      let candidate = current.isEmpty ? piece : current + " " + piece
      if current.isEmpty || writer.fits(candidate, extra: 2) {
        current = candidate
      } else {
        writer.line("  " + current)
        current = piece
      }
    }
    writer.line("  " + current)
    writer.line("]" + end)
  }
}

/// FactsEntry is one operation's facts, as the printed table writes them.
struct FactsEntry {
  let surface: String
  let operationId: String
  let method: String
  let path: String
  let idempotent: Bool
  /// actingUser is the operation's `x-acting-user`, which is printed where it is not `none`.
  let actingUser: String
  /// credentials is each other credential fact that is true, by name, in the contract's order.
  let credentials: [String]
  let timeoutMs: Int?
  let declaresIdempotencyKey: Bool
  let isConditional: Bool
  let answersNotModified: Bool
  let pagination: Operation.Pagination?
  let success: String
  /// successResponses is every status a success arrives with and the headers the contract
  /// declares on it, by name, each in the contract's order.
  let successResponses: [(status: Int, headers: [String])]
  let errorStatuses: [Int]
  /// tasks is every task the operation triggers, in the contract's order.
  let tasks: [String]

  init(_ operation: Operation, surface: String) throws(PrinterError) {
    self.surface = surface
    operationId = operation.operationId
    method = operation.method
    path = operation.path
    idempotent = operation.idempotent
    actingUser = operation.credentials.actingUser
    credentials = Self.facts(operation.credentials)
    timeoutMs = operation.timeoutMs
    declaresIdempotencyKey = operation.idempotencyKey
    isConditional = operation.conditional
    answersNotModified = operation.notModified
    pagination = operation.pagination
    switch operation.success {
    case .envelope: success = "envelope"
    case .eventStream: success = "eventStream"
    case .binary: success = "binary"
    }
    successResponses = operation.successResponses.map { response in
      (status: response.status, headers: response.headers.map(\.name))
    }
    errorStatuses = operation.errorStatuses
    tasks = operation.tasks
  }

  /// Creates a Data API operation's facts, its credentials, its success's statuses and its budget
  /// read from the model as a REST operation's are. Every Data API operation is a `POST` to the
  /// one endpoint, safe to repeat, and its success is the operation's own field of GraphQL's
  /// `data`, which the model states no kind of and no task for. A query is declared a read
  /// whatever method it travels over (`sdk/SPEC.md` §1).
  init(data operation: DataOperationModel, endpoint: String) {
    surface = "data"
    operationId = operation.name
    method = "POST"
    path = endpoint
    idempotent = true
    actingUser = operation.credentials.actingUser
    credentials = Self.facts(operation.credentials) + (operation.isQuery ? ["isRead"] : [])
    timeoutMs = operation.timeoutMs
    declaresIdempotencyKey = false
    isConditional = false
    answersNotModified = false
    pagination = nil
    success = "result"
    successResponses = operation.successResponses.map { response in
      (status: response.status, headers: response.headers.map(\.name))
    }
    errorStatuses = []
    tasks = []
  }

  /// facts is each credential fact but the acting user that an operation declares true, by name,
  /// in the contract's order.
  private static func facts(_ declared: Operation.Credentials) -> [String] {
    [
      ("acceptsShareToken", declared.acceptsShareToken),
      ("requiresSession", declared.requiresSession),
      ("requiresSecretKey", declared.requiresSecretKey),
      ("takesNoCredential", declared.takesNoCredential),
      ("pendingInvitee", declared.pendingInvitee),
    ].filter(\.1).map(\.0)
  }

  func write(_ writer: inout SourceWriter) {
    writer.line("static let \(SwiftText.identifier(operationId)) = OperationFacts(")
    writer.nestedLines { writer in
      writer.line("surface: .\(surface),")
      writer.line("operationId: \(SwiftText.literal(operationId)),")
      writer.line("method: \(SwiftText.literal(method)),")
      Self.path(&writer, path: path)
      writer.line("idempotent: \(idempotent),")
      let declared =
        (actingUser == "none" ? [] : ["actingUser: .\(actingUser)"])
        + credentials.map { "\($0): true" }
      writer.call(
        prefix: "credentials: ", callee: "CredentialDeclaration", arguments: declared, suffix: ",")
      writer.line("timeout: \(timeoutMs.map { ".milliseconds(\($0))" } ?? "nil"),")
      writer.line("declaresIdempotencyKey: \(declaresIdempotencyKey),")
      writer.line("isConditional: \(isConditional),")
      writer.line("answersNotModified: \(answersNotModified),")
      if let pagination {
        let sort = pagination.sort.map(SwiftText.literal).joined(separator: ", ")
        writer.call(
          prefix: "pagination: ", callee: "Pagination",
          arguments: [
            "sort: [\(sort)]",
            "defaultSort: \(pagination.defaultSort.map(SwiftText.literal) ?? "nil")",
          ], suffix: ",")
      } else {
        writer.line("pagination: nil,")
      }
      writer.line("success: .\(success),")
      Self.successResponses(&writer, responses: successResponses)
      writer.line("errorStatuses: \(Self.list(errorStatuses)),")
      Self.strings(&writer, label: "tasks", elements: tasks.map(SwiftText.literal))
    }
    writer.line(")")
  }

  /// strings writes the call's last argument, a list of string literals, as the formatter lays
  /// an array literal out: on one line where it fits, and otherwise broken after the bracket,
  /// as many elements to a line as fit, each followed by a comma.
  private static func strings(_ writer: inout SourceWriter, label: String, elements: [String]) {
    let whole = "\(label): [\(elements.joined(separator: ", "))]"
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    writer.line("\(label): [")
    var current = ""
    for element in elements {
      let piece = element + ","
      let candidate = current.isEmpty ? piece : current + " " + piece
      if current.isEmpty || writer.fits(candidate, extra: 2) {
        current = candidate
      } else {
        writer.line("  " + current)
        current = piece
      }
    }
    writer.line("  " + current)
    writer.line("]")
  }

  /// path writes the path's literal, broken where its line does not fit into literals joined
  /// by `+`, as the formatter lays a concatenation out, each piece ending before a `/`.
  private static func path(_ writer: inout SourceWriter, path: String) {
    let whole = "path: \(SwiftText.literal(path)),"
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    var segments: [String] = []
    for character in path {
      if character == "/" || segments.isEmpty {
        segments.append(String(character))
      } else {
        segments[segments.count - 1].append(character)
      }
    }
    var pieces: [String] = []
    for segment in segments {
      let head = pieces.count == 1 ? "path: " : "  + "
      if let last = pieces.last, writer.fits(head + SwiftText.literal(last + segment) + ",") {
        pieces[pieces.count - 1] = last + segment
      } else {
        pieces.append(segment)
      }
    }
    for (position, piece) in pieces.enumerated() {
      let head = position == 0 ? "path: " : "  + "
      writer.line(head + SwiftText.literal(piece) + (position == pieces.count - 1 ? "," : ""))
    }
  }

  /// successResponses writes the list of a success's statuses and the headers each declares, as
  /// the formatter lays an array literal out: on one line where it fits, and otherwise one
  /// element to a line, a comma after each where there is more than one.
  private static func successResponses(
    _ writer: inout SourceWriter,
    responses: [(status: Int, headers: [String])]
  ) {
    let elements = responses.map { response in
      [
        "status: \(response.status)",
        "headers: [\(response.headers.map(SwiftText.literal).joined(separator: ", "))]",
      ]
    }
    let whole =
      "successResponses: ["
      + elements.map { "SuccessResponse(\($0.joined(separator: ", ")))" }.joined(separator: ", ")
      + "],"
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    writer.line("successResponses: [")
    writer.nestedLines { writer in
      for arguments in elements {
        writer.call(
          prefix: "", callee: "SuccessResponse", arguments: arguments,
          suffix: elements.count > 1 ? "," : "")
      }
    }
    writer.line("],")
  }

  private static func list(_ statuses: [Int]) -> String {
    "[\(statuses.map(String.init).joined(separator: ", "))]"
  }
}

extension Property {
  /// Creates the property a query parameter is on its query type.
  init(parameter: Parameter) {
    self.init(
      name: parameter.name,
      required: parameter.required,
      type: parameter.type,
      description: parameter.description,
      discriminatorValue: nil,
      deprecated: parameter.deprecated
    )
  }
}
