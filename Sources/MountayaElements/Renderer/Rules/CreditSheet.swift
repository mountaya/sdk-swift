#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaGeo
  internal import UIKit

  /// creditSheet is the sheet a map's credit button opens: one action per credit, in the order the
  /// engine credits them, Mountaya first (`map.style.attribution`), each titled with the text the
  /// credit's markup shows and opening its link through `open`, and one that closes the sheet.
  ///
  /// A credit is markup, as a style's sources write one, and the sheet shows it as MapLibre's own
  /// credit button shows a source's: the text it holds, its tags dropped and its entities read, so
  /// `<a href="https://mountaya.com/">&copy; Mountaya</a>` reads `© Mountaya` and opens
  /// `https://mountaya.com/`. A credit with no link is shown and opens nothing.
  @MainActor
  func creditSheet(_ credits: [String], open: @escaping @MainActor (URL) -> Void)
    -> UIAlertController
  {
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    for credit in credits {
      let link = creditLink(credit)
      sheet.addAction(
        UIAlertAction(title: link.text, style: .default) { _ in
          if let url = link.url {
            open(url)
          }
        })
    }
    sheet.addAction(UIAlertAction(title: "OK", style: .cancel))
    return sheet
  }

  /// creditLink reads a credit's markup into the text it shows, its tags dropped, its entities
  /// read and the white space at its ends trimmed, and the address its first `href` names, nil
  /// where it names none or no address.
  func creditLink(_ markup: String) -> (text: String, url: URL?) {
    var text = ""
    var inTag = false
    for character in markup {
      switch character {
      case "<": inTag = true
      case ">": inTag = false
      default:
        if !inTag { text.append(character) }
      }
    }
    return (
      trimWhiteSpace(readEntities(text)),
      firstHref(markup).flatMap { URL(string: readEntities($0)) }
    )
  }

  /// firstHref is the value of the first `href` attribute the markup writes, between the quotes
  /// that open it.
  private func firstHref(_ markup: String) -> String? {
    guard let attribute = markup.range(of: "href=") else { return nil }
    let rest = markup[attribute.upperBound...]
    guard let quote = rest.first, quote == "\"" || quote == "'" else { return nil }
    let value = rest.dropFirst()
    guard let end = value.firstIndex(of: quote) else { return nil }
    return String(value[..<end])
  }

  /// readEntities reads the character references of a text: the named ones a credit writes and
  /// every numeric one, a reference it cannot read kept as written.
  private func readEntities(_ text: String) -> String {
    let named: [String: String] = [
      "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "copy": "\u{A9}",
      "reg": "\u{AE}", "nbsp": "\u{A0}",
    ]
    var read = ""
    var rest = Substring(text)
    while let start = rest.firstIndex(of: "&") {
      read += rest[..<start]
      let after = rest[rest.index(after: start)...]
      guard let end = after.firstIndex(of: ";") else {
        read += rest[start...]
        return read
      }
      let name = String(after[..<end])
      var replacement: String?
      if name.hasPrefix("#x") || name.hasPrefix("#X") {
        replacement = UInt32(name.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map {
          String($0)
        }
      } else if name.hasPrefix("#") {
        replacement = UInt32(name.dropFirst()).flatMap(Unicode.Scalar.init).map { String($0) }
      } else {
        replacement = named[name]
      }
      if let replacement {
        read += replacement
        rest = after[after.index(after: end)...]
      } else {
        read += "&"
        rest = after
      }
    }
    return read + rest
  }
#endif
