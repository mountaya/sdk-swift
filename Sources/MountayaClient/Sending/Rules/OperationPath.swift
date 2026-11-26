import Foundation

/// OperationPath fills an operation's path template.
enum OperationPath {
  /// substitute returns `template` with each `{name}` replaced by its parameter's value,
  /// percent-encoded as one path segment.
  ///
  /// Only RFC 3986's unreserved characters stay as they are, so a value holding a `/`, a `?`
  /// or a `#` stays inside its own segment rather than moving the request somewhere else. A
  /// placeholder with no parameter is left as written, which a generated call never does.
  static func substitute(_ template: String, with parameters: KeyValuePairs<String, String>)
    -> String
  {
    var path = template
    for (name, value) in parameters {
      path = path.replacingOccurrences(of: "{\(name)}", with: segment(value))
    }
    return path
  }

  /// segment percent-encodes a value as one path segment: every byte of its UTF-8 outside
  /// `A-Z a-z 0-9 - . _ ~` becomes `%XX`, in uppercase hexadecimal.
  static func segment(_ value: String) -> String {
    var encoded = ""
    for byte in value.utf8 {
      if isUnreserved(byte) {
        encoded.unicodeScalars.append(Unicode.Scalar(byte))
      } else {
        encoded += "%" + hex(byte >> 4) + hex(byte & 0x0F)
      }
    }
    return encoded
  }

  private static func isUnreserved(_ byte: UInt8) -> Bool {
    switch byte {
    case UInt8(ascii: "A")...UInt8(ascii: "Z"), UInt8(ascii: "a")...UInt8(ascii: "z"),
      UInt8(ascii: "0")...UInt8(ascii: "9"), UInt8(ascii: "-"), UInt8(ascii: "."),
      UInt8(ascii: "_"), UInt8(ascii: "~"):
      return true
    default:
      return false
    }
  }

  private static func hex(_ nibble: UInt8) -> String {
    String(nibble, radix: 16, uppercase: true)
  }
}
