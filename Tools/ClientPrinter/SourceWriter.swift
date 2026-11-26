/// SourceWriter accumulates a file's lines at an indentation of two spaces a level.
struct SourceWriter {
  private(set) var lines: [String] = []
  private var depth = 0

  var indent: Int {
    depth * 2
  }

  /// line writes one line at the current indentation, or an empty line for an empty text.
  mutating func line(_ text: String = "") {
    lines.append(text.isEmpty ? "" : String(repeating: " ", count: indent) + text)
  }

  /// doc writes a description as `///` lines at the current indentation.
  mutating func doc(_ text: String) {
    lines += SwiftText.docLines(text, indent: indent)
  }

  /// block writes `opening`, the body one level in, and the closing brace.
  mutating func block(_ opening: String, body: (inout SourceWriter) throws(PrinterError) -> Void)
    throws(PrinterError)
  {
    line(opening)
    depth += 1
    try body(&self)
    depth -= 1
    line("}")
  }

  /// nested runs `body` one level in, with no braces written.
  mutating func nested(_ body: (inout SourceWriter) throws(PrinterError) -> Void)
    throws(PrinterError)
  {
    depth += 1
    try body(&self)
    depth -= 1
  }

  /// nestedLines runs `body` one level in, with no braces written.
  mutating func nestedLines(_ body: (inout SourceWriter) -> Void) {
    depth += 1
    body(&self)
    depth -= 1
  }

  /// fits is true where a line of `text` at the current indentation stays within the column.
  func fits(_ text: String, extra: Int = 0) -> Bool {
    indent + extra + text.count <= SwiftText.lineLength
  }

  /// call writes `prefix callee(arguments)suffix` as the formatter lays it out: on one line
  /// where it fits; otherwise broken after the parenthesis, with the arguments on one
  /// continuation line where they fit there, and one to a line where they do not, the closing
  /// parenthesis following the last.
  mutating func call(
    prefix: String,
    callee: String,
    arguments: [String],
    suffix: String = ""
  ) {
    let whole = "\(prefix)\(callee)(\(arguments.joined(separator: ", ")))\(suffix)"
    if fits(whole) {
      line(whole)
      return
    }
    line("\(prefix)\(callee)(")
    let packed = "\(arguments.joined(separator: ", ")))\(suffix)"
    if fits(packed, extra: 2) {
      line("  " + packed)
      return
    }
    for (position, argument) in arguments.enumerated() {
      let end = position == arguments.count - 1 ? ")\(suffix)" : ","
      line("  " + argument + end)
    }
  }

  /// assignment writes `head = value` as the formatter lays it out: on one line where it fits,
  /// and otherwise broken after the `=`, the value one level in.
  mutating func assignment(_ head: String, value: String) {
    let whole = "\(head) = \(value)"
    if fits(whole) {
      line(whole)
    } else {
      line("\(head) =")
      line("  " + value)
    }
  }

  /// text is the file: the lines joined, one newline at the end, and never two blank lines
  /// in a row.
  var text: String {
    var kept: [String] = []
    for line in lines where !(line.isEmpty && kept.last?.isEmpty == true) {
      kept.append(line)
    }
    while kept.last?.isEmpty == true {
      kept.removeLast()
    }
    return kept.joined(separator: "\n") + "\n"
  }
}
