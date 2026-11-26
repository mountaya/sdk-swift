/// Registry is the contract's list of capabilities, read from `sdk/registry.yaml`.
package struct Registry: Sendable {
  package let version: Int
  package let capabilities: [Capability]

  /// Capability is one entry of the registry.
  package struct Capability: Sendable, Hashable {
    package let id: String
    package let layer: Layer
    package let api: Bool
    package let rule: String
    package let fixture: String
    /// published is the public declarations a consumer calls for the capability, as each SDK
    /// spells them, nil on an entry that states none.
    package let published: Published?
    /// line is where the entry starts in the file, for a message that points at it.
    package let line: Int

    package init(
      id: String, layer: Layer, api: Bool, rule: String, fixture: String,
      published: Published? = nil, line: Int
    ) {
      self.id = id
      self.layer = layer
      self.api = api
      self.rule = rule
      self.fixture = fixture
      self.published = published
      self.line = line
    }
  }

  package init(version: Int, capabilities: [Capability]) {
    self.version = version
    self.capabilities = capabilities
  }

  /// Layer is the layer of the contract that owns a capability, as the registry names it.
  ///
  /// `map` is the rendering engines' own behaviour, which an SDK whose elements binding drives a
  /// renderer reproduces, and which this SDK runs rather than scopes.
  package enum Layer: String, Sendable, Hashable, CaseIterable {
    case transport
    case geo
    case map
    case studio
  }

  /// SDK is one of the four SDKs a `published` mapping records names for, by its key there.
  package enum SDK: String, Sendable, Hashable, CaseIterable {
    case typescript
    case dart
    case swift
    case kotlin
  }

  /// Published is an entry's `published` mapping: for each of the four SDKs, the exact spelling of
  /// every declaration a consumer calls for the capability, as that SDK's own record of its API
  /// prints it, or `scoped` where that SDK does not carry the capability. This SDK's column is
  /// written as the paths of its API baselines (SPEC.md section 5): `MapEngine.features(at:)`,
  /// `APIError.Kind.preconditionFailed`, `GlyphSet.init(chaining:)`.
  package struct Published: Sendable, Hashable {
    package let typescript: Column
    package let dart: Column
    package let swift: Column
    package let kotlin: Column

    package init(typescript: Column, dart: Column, swift: Column, kotlin: Column) {
      self.typescript = typescript
      self.dart = dart
      self.swift = swift
      self.kotlin = kotlin
    }
  }

  /// Column is one SDK's names for a capability, or `scoped` where it does not carry it.
  package enum Column: Sendable, Hashable {
    case scoped
    case names([String])
  }
}

/// RegistryError names the line of the registry this reader could not read.
package struct RegistryError: Error, Sendable, CustomStringConvertible {
  package let line: Int
  package let message: String

  package var description: String {
    "sdk/registry.yaml line \(line): \(message)"
  }
}

extension Registry {
  /// parse reads the registry's text.
  ///
  /// The file has one fixed shape, which the contract's own gate enforces: a `version`, then
  /// `capabilities` as a list of entries carrying `id`, `layer`, `api`, a folded `rule`,
  /// `fixture` and, on an entry a consumer calls, `published` as a mapping of exactly four keys,
  /// `typescript`, `dart`, `swift` and `kotlin`, each `scoped` on its own line or a list of names
  /// below it, none twice. A name of the `swift` list is a path of this SDK's API baselines; the
  /// other lists are read as names and left to the contract's gate. This reader knows that shape
  /// and nothing else of YAML. Anything it does not recognise is an error naming the line, so a
  /// registry that outgrows it fails loudly instead of being half read.
  package static func parse(_ text: String) throws(RegistryError) -> Registry {
    var version: Int?
    var sawCapabilities = false
    var capabilities: [Capability] = []
    var draft: Draft?
    var inRule = false
    var inPublished = false
    // The column whose list the lines at indent 8 extend, nil where none is open.
    var column: SDK?

    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    for (offset, rawLine) in lines.enumerated() {
      let number = offset + 1
      let line = rawLine.hasSuffix("\r") ? rawLine.dropLast() : rawLine
      let trimmed = line.drop { $0 == " " }
      if trimmed.isEmpty || trimmed.hasPrefix("#") {
        continue
      }
      if line.contains("\t") {
        throw RegistryError(line: number, message: "a tab, where the file indents with spaces")
      }
      let indent = line.count - trimmed.count

      if inRule {
        if indent >= 6 {
          draft?.ruleLines.append(String(trimmed))
          continue
        }
        inRule = false
      }
      if inPublished {
        if indent == 6 {
          guard let colon = trimmed.firstIndex(of: ":"),
            let sdk = SDK(rawValue: String(trimmed[..<colon]))
          else {
            throw RegistryError(
              line: number,
              message: "expected `typescript`, `dart`, `swift` or `kotlin` under `published`")
          }
          guard draft?.columns[sdk] == nil else {
            throw RegistryError(line: number, message: "`\(sdk.rawValue)` appears twice")
          }
          switch value(of: sdk.rawValue, in: trimmed) {
          case "scoped"?:
            draft?.columns[sdk] = .scoped
            column = nil
          case ""?:
            draft?.columns[sdk] = .names([])
            column = sdk
          default:
            throw RegistryError(
              line: number,
              message: "`\(sdk.rawValue)` is `scoped`, or a list, one `- <name>` a line")
          }
          draft?.columnLines[sdk] = number
          continue
        }
        if indent == 8 {
          guard let sdk = column, case .names(let names)? = draft?.columns[sdk] else {
            throw RegistryError(line: number, message: "a name outside any column of `published`")
          }
          guard trimmed.hasPrefix("- ") else {
            throw RegistryError(
              line: number, message: "expected `- <name>` under `\(sdk.rawValue)`")
          }
          let name = String(trimmed.dropFirst(2))
          if sdk == .swift {
            guard isSwiftSpelling(name) else {
              throw RegistryError(
                line: number,
                message: "`\(name)` is no path of an API baseline, such as `Type.member(label:)`")
            }
          } else {
            guard isName(name) else {
              throw RegistryError(line: number, message: "`\(name)` is not a name")
            }
          }
          guard !names.contains(name) else {
            throw RegistryError(
              line: number, message: "`\(name)` is published twice under `\(sdk.rawValue)`")
          }
          draft?.columns[sdk] = .names(names + [name])
          continue
        }
        guard indent < 6 else {
          throw RegistryError(
            line: number, message: "unrecognised indentation of \(indent) spaces under `published`")
        }
        inPublished = false
        column = nil
      }

      switch indent {
      case 0:
        if let value = value(of: "version", in: trimmed) {
          guard version == nil else {
            throw RegistryError(line: number, message: "`version` appears twice")
          }
          guard let parsed = Int(value), parsed > 0 else {
            throw RegistryError(line: number, message: "`version` is not a positive integer")
          }
          version = parsed
        } else if trimmed == "capabilities:" {
          guard !sawCapabilities else {
            throw RegistryError(line: number, message: "`capabilities` appears twice")
          }
          sawCapabilities = true
        } else {
          throw RegistryError(line: number, message: "unrecognised top-level line `\(trimmed)`")
        }
      case 2:
        guard sawCapabilities, trimmed.hasPrefix("- "),
          let id = value(of: "id", in: trimmed.dropFirst(2))
        else {
          throw RegistryError(line: number, message: "expected `- id: <id>`")
        }
        if let finished = draft {
          capabilities.append(try finished.capability())
        }
        guard isIdentifier(id) else {
          throw RegistryError(line: number, message: "`\(id)` is not a capability id")
        }
        draft = Draft(id: id, line: number)
      case 4:
        guard draft != nil else {
          throw RegistryError(line: number, message: "a field outside any entry")
        }
        if let layer = value(of: "layer", in: trimmed) {
          guard draft?.layer == nil else {
            throw RegistryError(line: number, message: "`layer` appears twice")
          }
          guard let parsed = Layer(rawValue: layer) else {
            throw RegistryError(line: number, message: "unknown layer `\(layer)`")
          }
          draft?.layer = parsed
        } else if let api = value(of: "api", in: trimmed) {
          guard draft?.api == nil else {
            throw RegistryError(line: number, message: "`api` appears twice")
          }
          guard api == "true" || api == "false" else {
            throw RegistryError(line: number, message: "`api` is neither true nor false")
          }
          draft?.api = api == "true"
        } else if let fixture = value(of: "fixture", in: trimmed) {
          guard draft?.fixture == nil else {
            throw RegistryError(line: number, message: "`fixture` appears twice")
          }
          guard isFixturePath(fixture) else {
            throw RegistryError(line: number, message: "`\(fixture)` is not a fixture path")
          }
          draft?.fixture = fixture
        } else if let rule = value(of: "rule", in: trimmed) {
          guard draft?.sawRule == false else {
            throw RegistryError(line: number, message: "`rule` appears twice")
          }
          guard rule == ">-" else {
            throw RegistryError(line: number, message: "`rule` is expected as a folded block, `>-`")
          }
          draft?.sawRule = true
          inRule = true
        } else if let published = value(of: "published", in: trimmed) {
          guard draft?.publishedLine == nil else {
            throw RegistryError(line: number, message: "`published` appears twice")
          }
          guard published.isEmpty else {
            throw RegistryError(
              line: number, message: "`published` is expected as a mapping, one SDK's key a line")
          }
          draft?.publishedLine = number
          inPublished = true
        } else {
          throw RegistryError(line: number, message: "unrecognised field `\(trimmed)`")
        }
      default:
        throw RegistryError(line: number, message: "unrecognised indentation of \(indent) spaces")
      }
    }

    if let finished = draft {
      capabilities.append(try finished.capability())
    }
    guard let version else {
      throw RegistryError(line: lines.count, message: "no `version`")
    }
    var seen: Set<String> = []
    for capability in capabilities where !seen.insert(capability.id).inserted {
      throw RegistryError(line: capability.line, message: "`\(capability.id)` is declared twice")
    }
    return Registry(version: version, capabilities: capabilities)
  }

  /// Returns the scalar after `key: `, or nil when the line is not that key. A quoted value or
  /// a trailing comment is not a form the file uses, and reads as itself, so the checks on the
  /// value refuse it.
  private static func value(of key: String, in line: Substring) -> String? {
    let prefix = key + ":"
    guard line.hasPrefix(prefix) else { return nil }
    let rest = line.dropFirst(prefix.count)
    guard rest.isEmpty || rest.hasPrefix(" ") else { return nil }
    return String(rest.drop { $0 == " " })
  }

  private static func isIdentifier(_ value: String) -> Bool {
    !value.isEmpty
      && value.split(separator: ".", omittingEmptySubsequences: false).allSatisfy {
        segment in
        !segment.isEmpty
          && segment.utf8.allSatisfy { byte in
            (byte >= 0x61 && byte <= 0x7A) || (byte >= 0x30 && byte <= 0x39) || byte == 0x2D
          }
      }
  }

  /// isSwiftSpelling is true of a path as this SDK's API baselines print one: names joined by
  /// dots, each a letter followed by letters and digits, the last of which may carry its argument
  /// labels, each a label or `_` followed by a colon. `BaseURLs`, `haversineMeters(from:to:)`,
  /// `APIError.Kind.preconditionFailed` and `MapEngine.close()` are such paths.
  private static func isSwiftSpelling(_ value: String) -> Bool {
    var path = Substring(value)
    if let open = path.firstIndex(of: "(") {
      guard path.hasSuffix(")") else { return false }
      let labels = path[path.index(after: open)..<path.index(before: path.endIndex)]
      guard labels.isEmpty || labels.hasSuffix(":") else { return false }
      let isLabelled = labels.split(separator: ":", omittingEmptySubsequences: false).dropLast()
        .allSatisfy { $0 == "_" || isWord($0) }
      guard isLabelled else { return false }
      path = path[..<open]
    }
    return path.split(separator: ".", omittingEmptySubsequences: false).allSatisfy(isWord)
  }

  /// isName is true of a name another SDK's column lists, which this reader holds to no
  /// language's spelling, the contract's own gate doing that: a letter, `_` or `$`, then no blank,
  /// quote or comment.
  private static func isName(_ value: String) -> Bool {
    guard let first = value.utf8.first,
      isLetter(first) || first == UInt8(ascii: "_") || first == UInt8(ascii: "$")
    else { return false }
    return value.utf8.allSatisfy { byte in
      byte > 0x20 && byte < 0x7F && byte != UInt8(ascii: "\"") && byte != UInt8(ascii: "'")
        && byte != UInt8(ascii: "#")
    }
  }

  /// isWord is true of a letter followed by letters and digits.
  private static func isWord(_ part: Substring) -> Bool {
    guard let first = part.utf8.first, isLetter(first) else { return false }
    return part.utf8.allSatisfy { isLetter($0) || ($0 >= 0x30 && $0 <= 0x39) }
  }

  private static func isLetter(_ byte: UInt8) -> Bool {
    (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
  }

  private static func isFixturePath(_ value: String) -> Bool {
    value.hasSuffix(".json") && !value.hasPrefix("/") && !value.contains("..")
      && value.utf8.allSatisfy { byte in
        (byte >= 0x61 && byte <= 0x7A) || (byte >= 0x30 && byte <= 0x39) || byte == 0x2D
          || byte == 0x2F || byte == 0x2E
      }
  }

  private struct Draft {
    let id: String
    let line: Int
    var layer: Layer?
    var api: Bool?
    var fixture: String?
    var sawRule = false
    var ruleLines: [String] = []
    /// publishedLine is the line of the entry's `published` key, nil where it has none.
    var publishedLine: Int?
    /// columns is each SDK's column as read so far, and columnLines the line of its key.
    var columns: [SDK: Column] = [:]
    var columnLines: [SDK: Int] = [:]

    func capability() throws(RegistryError) -> Capability {
      guard let layer else {
        throw RegistryError(line: line, message: "`\(id)` has no `layer`")
      }
      guard let api else {
        throw RegistryError(line: line, message: "`\(id)` has no `api`")
      }
      guard let fixture else {
        throw RegistryError(line: line, message: "`\(id)` has no `fixture`")
      }
      guard !ruleLines.isEmpty else {
        throw RegistryError(line: line, message: "`\(id)` has no `rule`")
      }
      return Capability(
        id: id,
        layer: layer,
        api: api,
        rule: ruleLines.joined(separator: " "),
        fixture: fixture,
        published: try published(),
        line: line
      )
    }

    /// published reads the four columns, each stated and each list naming something, or nil where
    /// the entry states none.
    private func published() throws(RegistryError) -> Published? {
      guard let publishedLine else { return nil }
      var stated: [SDK: Column] = [:]
      for sdk in SDK.allCases {
        guard let column = columns[sdk] else {
          throw RegistryError(
            line: publishedLine, message: "`\(id)` states no `\(sdk.rawValue)` under `published`")
        }
        if case .names(let names) = column, names.isEmpty {
          throw RegistryError(
            line: columnLines[sdk] ?? publishedLine,
            message: "`\(id)` lists no name under `\(sdk.rawValue)`")
        }
        stated[sdk] = column
      }
      return Published(
        typescript: stated[.typescript] ?? .scoped, dart: stated[.dart] ?? .scoped,
        swift: stated[.swift] ?? .scoped, kotlin: stated[.kotlin] ?? .scoped)
    }
  }
}
