/// StreamRefusal refuses a buffered request that asks for an event stream.
///
/// A stream has no end for a buffered read to wait on, so a request whose `Accept` names
/// `text/event-stream` among its media ranges, in any letter case and whatever parameters
/// follow it, is refused before its first attempt and nothing is sent: a stream is opened
/// through `events`, which reads it as one.
enum StreamRefusal {
  /// mediaType is the media type of a Server-Sent Events stream.
  static let mediaType = "text/event-stream"

  /// check refuses headers whose `Accept` asks for an event stream.
  static func check(_ headers: [String: String]) throws(MountayaError) {
    guard let accept = HeaderLookup.value(of: "Accept", in: headers), asksForStream(accept) else {
      return
    }
    throw .configuration(
      ConfigurationError(
        message:
          "This request asks for `text/event-stream`, which has no end for a buffered call to "
          + "read to: open it with `events(_:path:query:options:)`, or with the operation's own "
          + "stream method."
      )
    )
  }

  /// asksForStream returns whether an `Accept` value names an event stream among its ranges.
  static func asksForStream(_ accept: String) -> Bool {
    accept.split(separator: ",").contains { range in
      let type = range.split(separator: ";", maxSplits: 1).first ?? ""
      return HeaderLookup.asciiLowercase(String(type.trimmingSpace())) == mediaType
    }
  }
}

extension Substring {
  /// trimmingSpace returns the text without the spaces and tabs around it.
  fileprivate func trimmingSpace() -> Substring {
    var text = self
    while let first = text.first, first == " " || first == "\t" {
      text.removeFirst()
    }
    while let last = text.last, last == " " || last == "\t" {
      text.removeLast()
    }
    return text
  }
}
