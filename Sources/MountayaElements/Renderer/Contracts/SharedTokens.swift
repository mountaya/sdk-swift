#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo

  /// SharedTokens is the design tokens of a view's environment (`mountayaTokens`), held by one
  /// reference every view under the statement shares.
  ///
  /// A view of the elements reads its tokens through it, `@Environment(\.sharedTokens)`, and reads
  /// a token off it as off the tokens themselves, `tokens.accent`. SwiftUI's `Environment` stores
  /// the value it reads inline in the view, so a view reading the tokens whole would carry every
  /// token, two colours each, and every copy, move and release of the view would copy, move and
  /// release them all: code SwiftUI's value witnesses repeat for each view, in every app. A view
  /// reading this carries one reference instead.
  ///
  /// Two are equal where they hold equal tokens, so a statement of the same tokens drawn again
  /// draws no view reading them again. It is Sendable: it holds one constant, the tokens.
  @dynamicMemberLookup
  final class SharedTokens: Sendable, Equatable {
    /// standard is `ElementTokens.standard`, the tokens where no view states others.
    static let standard = SharedTokens(.standard)

    /// value is the tokens held.
    let value: ElementTokens

    /// Creates the reference holding `value`.
    init(_ value: ElementTokens) {
      self.value = value
    }

    /// The token, or any value of the tokens, `path` reads.
    subscript<Token>(dynamicMember path: KeyPath<ElementTokens, Token>) -> Token {
      value[keyPath: path]
    }

    /// Two are equal where they are one reference, or hold equal tokens.
    static func == (lhs: SharedTokens, rhs: SharedTokens) -> Bool {
      lhs === rhs || lhs.value == rhs.value
    }
  }
#endif
