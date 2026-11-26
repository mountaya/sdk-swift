#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo

  /// SharedScope is the elements scope of a view's environment (`mountayaScope`), held by one
  /// reference every view under the statement shares, as `SharedTokens` holds the tokens.
  ///
  /// A view of the elements reads its scope through it, `@Environment(\.sharedScope)`, and reads
  /// the scope's settings off it as off the scope itself, `scope.language`, and its words through
  /// `word(_:)`. SwiftUI's `Environment` stores the value it reads inline in the view, so a view
  /// reading the scope whole would carry its language, its locale, its words and its two glyph sets,
  /// and every copy, move and release of the view would copy, move and release them all: code
  /// SwiftUI's value witnesses repeat for each view, in every app. A view reading this carries one
  /// reference instead.
  ///
  /// Two are equal where they are one reference, or hold equal scopes, so a statement of the same
  /// scope drawn again draws no view reading it again. It is Sendable: it holds one constant, the
  /// scope.
  @dynamicMemberLookup
  final class SharedScope: Sendable, Equatable {
    /// standard is `ElementsScope.standard`, the scope where no view states another.
    static let standard = SharedScope(.standard)

    /// value is the scope held.
    let value: ElementsScope

    /// Creates the reference holding `value`.
    init(_ value: ElementsScope) {
      self.value = value
    }

    /// The setting of the scope `path` reads.
    subscript<Setting>(dynamicMember path: KeyPath<ElementsScope, Setting>) -> Setting {
      value[keyPath: path]
    }

    /// word is the word the scope reads at `path`, as `ElementsScope.word(_:)` reads it.
    func word(_ path: String) -> String {
      value.word(path)
    }

    /// Two are equal where they are one reference, or hold equal scopes.
    static func == (lhs: SharedScope, rhs: SharedScope) -> Bool {
      lhs === rhs || lhs.value == rhs.value
    }
  }
#endif
