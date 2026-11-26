/// filledText writes the template `template` with `value` in place of its placeholder
/// (`geo.i18n.counted-words`): the first `{name}` it holds, a name of ASCII letters and digits led
/// by a letter, read scalar by scalar.
///
/// The value is the one an element hands the word, which the locale services already wrote, and
/// it is written exactly as handed: `$&` and `\1` are text, never a pattern, so a figure that holds
/// them stays that figure. A template that holds no placeholder is written as it is. The elements'
/// words table writes a template with one placeholder, `"{elapsed} stop"`.
public func filledText(_ template: String, value: String) -> String {
  guard let placeholder = firstPlaceholder(in: template) else { return template }
  var filled = template
  filled.replaceSubrange(placeholder, with: value)
  return filled
}

/// filledText writes the template `template` with each of `values` in every placeholder of its
/// name (`geo.i18n.counted-words`): a template an element hands several values, as the readout's
/// band range hands `{min}` and `{max}` and a zone's window `{start}` and `{end}`, takes each
/// wherever the language's words put it, a name compared by its scalars, and writes a placeholder
/// no value names as it stands.
///
/// Each value is written exactly as handed, as `filledText(_:value:)` writes its one, and a value
/// is never read again for a placeholder: one holding `{max}` stays that text.
public func filledText(_ template: String, values: [String: String]) -> String {
  var written = String.UnicodeScalarView()
  var rest = String(template)
  while let placeholder = firstPlaceholder(in: rest) {
    let scalars = rest.unicodeScalars
    let nameStart = scalars.index(after: placeholder.lowerBound)
    let nameEnd = scalars.index(before: placeholder.upperBound)
    let name = String(scalars[nameStart..<nameEnd])
    written.append(contentsOf: scalars[..<placeholder.lowerBound])
    if let value = values.first(where: { sameText($0.key, name) })?.value {
      written.append(contentsOf: value.unicodeScalars)
    } else {
      written.append(contentsOf: scalars[placeholder])
    }
    rest = String(scalars[placeholder.upperBound...])
  }
  written.append(contentsOf: rest.unicodeScalars)
  return String(written)
}

/// firstPlaceholder is where the first placeholder `text` holds stands: `{`, a name of ASCII
/// letters and digits led by a letter, and `}`, the one named `name` where a name is given,
/// compared by its scalars, or nil where it holds none. It reads the text scalar by scalar, so a
/// placeholder stands where its scalars do, a mark combining with its brace included.
func firstPlaceholder(in text: String, named name: String? = nil) -> Range<String.Index>? {
  let scalars = text.unicodeScalars
  var index = scalars.startIndex
  while index < scalars.endIndex {
    defer { index = scalars.index(after: index) }
    guard scalars[index] == "{" else { continue }
    var cursor = scalars.index(after: index)
    var read = String.UnicodeScalarView()
    while cursor < scalars.endIndex, isNameScalar(scalars[cursor], leading: read.isEmpty) {
      read.append(scalars[cursor])
      cursor = scalars.index(after: cursor)
    }
    guard cursor < scalars.endIndex, scalars[cursor] == "}", !read.isEmpty else { continue }
    if let name, !sameText(String(read), name) { continue }
    return index..<scalars.index(after: cursor)
  }
  return nil
}

/// Whether `scalar` may stand in a placeholder's name: an ASCII letter, or an ASCII digit past its
/// first scalar.
private func isNameScalar(_ scalar: Unicode.Scalar, leading: Bool) -> Bool {
  switch scalar {
  case "a"..."z", "A"..."Z": true
  case "0"..."9": !leading
  default: false
  }
}
