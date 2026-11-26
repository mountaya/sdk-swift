/// MemberWords names an enum member by its words, which the contract's one rule reads off the name
/// the model gives it (`sdk/SPEC.md` section 9), and spells them as Swift spells a member.
///
/// A REST or Tile API member's name is its `x-enum-varnames` entry, its type's name followed by its
/// own (`TileLayerTypeLine`), so printed whole it would repeat the type at every use. Its words are
/// that name with the type's name taken off the front, split before each capital:
/// `TileSourceTypeRasterDem` leaves `Raster` and `Dem`. A Data API member's words are its name split
/// at each underscore: `HIKING_AND_TRAIL` is `HIKING`, `AND` and `TRAIL`. A first word that starts
/// with a digit keeps the last word of its type's name in front of it, since no identifier starts
/// with one: `ElevationTileSize512` leaves `Size` and `512`. Swift writes the words in
/// lowerCamelCase, `rasterDem`, `hikingAndTrail` and `size512`, and a word its grammar reserves is
/// escaped where the member is declared, as `SwiftText.identifier` escapes any name, and needs no
/// escape where it is used after a dot (`.continue`).
enum MemberWords {
  /// rest names a REST or Tile API member, from its `x-enum-varnames` name and its type's.
  static func rest(_ name: String, of type: String, in namespace: String) throws(PrinterError)
    -> String
  {
    guard name.hasPrefix(type) else {
      throw PrinterError(
        "\(namespace).\(type).\(name): does not start with its type's name, so no words can be "
          + "read off it")
    }
    var words: [String] = []
    for scalar in name.unicodeScalars.dropFirst(type.unicodeScalars.count) {
      if isUpper(scalar) || (words.isEmpty && isDigit(scalar)) {
        words.append(String(scalar))
      } else if !words.isEmpty, isLower(scalar) || isDigit(scalar) {
        words[words.count - 1].unicodeScalars.append(scalar)
      } else {
        throw PrinterError(
          "\(namespace).\(type).\(name): leaves no words after its type's name, each a capital "
            + "or a digit followed by lowercase letters and digits")
      }
    }
    guard !words.isEmpty else {
      throw PrinterError("\(namespace).\(type).\(name): leaves no words after its type's name")
    }
    return lowerCamel(withTypeWord(words, of: type))
  }

  /// data names a Data API member, from its name, which is its wire value, and its type's.
  static func data(_ name: String, of type: String, in namespace: String) throws(PrinterError)
    -> String
  {
    let words = name.split(separator: "_", omittingEmptySubsequences: false).map(String.init)
    for word in words {
      guard !word.isEmpty,
        word.unicodeScalars.allSatisfy({ isUpper($0) || isLower($0) || isDigit($0) })
      else {
        throw PrinterError(
          "\(namespace).\(type).\(name): is no words split at each underscore, each letters and "
            + "digits")
      }
    }
    return lowerCamel(withTypeWord(words, of: type))
  }

  /// lowerCamel writes words in lowerCamelCase: the first in lowercase, and each after it in
  /// lowercase with its first letter uppercased.
  static func lowerCamel(_ words: [String]) -> String {
    words.enumerated().map { position, word in
      let lower = word.lowercased()
      return position == 0 ? lower : lower.prefix(1).uppercased() + lower.dropFirst()
    }.joined()
  }

  /// withTypeWord puts the last word of the type's name in front of a first word that starts
  /// with a digit.
  private static func withTypeWord(_ words: [String], of type: String) -> [String] {
    guard let first = words.first?.unicodeScalars.first, isDigit(first) else { return words }
    return [lastWord(of: type)] + words
  }

  /// lastWord is a type's last word: from its last capital to its end, or the whole name where
  /// what follows that capital is not lowercase letters and digits.
  private static func lastWord(of type: String) -> String {
    let scalars = Array(type.unicodeScalars)
    guard let start = scalars.lastIndex(where: isUpper),
      scalars[(start + 1)...].allSatisfy({ isLower($0) || isDigit($0) })
    else { return type }
    return String(String.UnicodeScalarView(scalars[start...]))
  }

  private static func isUpper(_ scalar: Unicode.Scalar) -> Bool {
    ("A"..."Z").contains(scalar)
  }

  private static func isLower(_ scalar: Unicode.Scalar) -> Bool {
    ("a"..."z").contains(scalar)
  }

  private static func isDigit(_ scalar: Unicode.Scalar) -> Bool {
    ("0"..."9").contains(scalar)
  }
}
