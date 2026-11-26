import Foundation

/// FormBody writes a `multipart/form-data` body.
enum FormBody {
  /// Written is a body and the `Content-Type` that names its boundary.
  struct Written: Sendable, Hashable {
    let contentType: String
    let bytes: Data
  }

  /// base is the boundary a body takes where no part holds it.
  static let base = "MountayaFormBoundary7Hq2Xw"

  /// fileType is the media type a file's part is sent as where it is given none, as RFC 7578 labels
  /// such a part: a printed form names its own, the one the model's encoding states for the part,
  /// and a part a caller builds may name another.
  static let fileType = "application/octet-stream"

  /// write returns `parts` as one body, in their order, each named by its form field, a text part
  /// with no media type, and a file's part stating its file name where it is given one and its
  /// media type, `application/octet-stream` where it is given none.
  ///
  /// The boundary is the same for every body but where a part's bytes hold it, which lengthens
  /// it until none does, so two writes of the same parts send the same bytes.
  static func write(_ parts: [MultipartPart]) -> Written {
    var boundary = base
    while parts.contains(where: { holds($0, boundary: boundary) }) {
      boundary += "x"
    }
    var bytes = Data()
    for part in parts {
      bytes.append(Data("--\(boundary)\r\n".utf8))
      var disposition = "Content-Disposition: form-data; name=\"\(escaped(part.name))\""
      var type: String?
      if case .file(_, let filename, let contentType) = part.content {
        if let filename {
          disposition += "; filename=\"\(escaped(filename))\""
        }
        type = contentType ?? fileType
      }
      bytes.append(Data((disposition + "\r\n").utf8))
      if let type {
        bytes.append(Data("Content-Type: \(type)\r\n".utf8))
      }
      bytes.append(Data("\r\n".utf8))
      switch part.content {
      case .text(let text): bytes.append(Data(text.utf8))
      case .file(let data, _, _): bytes.append(data)
      }
      bytes.append(Data("\r\n".utf8))
    }
    bytes.append(Data("--\(boundary)--\r\n".utf8))
    return Written(contentType: "multipart/form-data; boundary=\(boundary)", bytes: bytes)
  }

  /// contentTypes is every media type a file's part of `parts` states, which a header of the part
  /// carries, so the transport refuses one no header can carry before any request.
  static func contentTypes(_ parts: [MultipartPart]) -> [String] {
    parts.compactMap { part in
      guard case .file(_, _, let contentType) = part.content else { return nil }
      return contentType
    }
  }

  private static func holds(_ part: MultipartPart, boundary: String) -> Bool {
    let marker = Data(boundary.utf8)
    switch part.content {
    case .text(let text): return Data(text.utf8).range(of: marker) != nil
    case .file(let data, _, _): return data.range(of: marker) != nil
    }
  }

  /// escaped writes a field name or a file name inside its quotes, a quote and a line break
  /// percent-encoded as HTML's form encoding writes them.
  private static func escaped(_ name: String) -> String {
    name.replacingOccurrences(of: "\"", with: "%22")
      .replacingOccurrences(of: "\r", with: "%0D")
      .replacingOccurrences(of: "\n", with: "%0A")
  }
}
