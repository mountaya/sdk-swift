import Crypto
import Foundation

/// ModelDigest is the digest `sdk/SPEC.md` §11 defines of what every SDK prints from,
/// `modelDigest`: the model and the elements' data, five files of the contract checkout, which a
/// tag cannot name between two releases and a digest can (SPEC.md section 3).
///
/// It is the lowercase hexadecimal SHA-256 of, for each input in the order `inputs` lists, its
/// path from the checkout's root, a line feed, its length in bytes in decimal digits, a line feed,
/// then its bytes exactly as the checkout holds them. The printer writes it beside `schemaVersion`
/// and into every printed file's header, and the conformance report carries the digest of the
/// files its run read.
package enum ModelDigest {
  /// inputs is the five files the digest reads, each by its path from the checkout's root, in the
  /// order it reads them, which is part of the definition.
  package static let inputs = [
    "sdk/model.json",
    "sdk/elements/words.json",
    "sdk/elements/tokens.json",
    "sdk/elements/glyphs.json",
    "sdk/elements/NOTICE",
  ]

  /// File is one input, its path from the checkout's root and its bytes.
  package typealias File = (path: String, bytes: Data)

  /// Unreadable says which input of a checkout could not be read.
  package struct Unreadable: Error, Sendable, CustomStringConvertible {
    package let path: String

    package var description: String {
      "\(path) cannot be read, so the model's digest cannot be taken"
    }
  }

  /// digest answers the digest of `files`, each a path and its bytes, in the order given.
  package static func digest(of files: [File]) -> String {
    var hash = SHA256()
    for file in files {
      hash.update(data: Data("\(file.path)\n\(file.bytes.count)\n".utf8))
      hash.update(data: file.bytes)
    }
    return hash.finalize().map { byte in
      let hex = String(byte, radix: 16)
      return byte < 16 ? "0" + hex : hex
    }.joined()
  }

  /// bytes reads the inputs from a checkout, in order, exactly as it holds them.
  package static func bytes(inCheckout root: URL) throws(Unreadable) -> [File] {
    var files: [File] = []
    for path in inputs {
      guard let bytes = try? Data(contentsOf: root.appendingPathComponent(path)) else {
        throw Unreadable(path: path)
      }
      files.append((path, bytes))
    }
    return files
  }

  /// digest(ofCheckout:) reads the inputs from a checkout and answers their digest.
  package static func digest(ofCheckout root: URL) throws(Unreadable) -> String {
    digest(of: try bytes(inCheckout: root))
  }
}
