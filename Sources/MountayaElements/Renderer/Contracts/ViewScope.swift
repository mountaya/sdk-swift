#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  import MountayaGeo
  internal import SwiftUI

  /// ViewScope is the elements scope a view of the elements reads its words in: the scope SwiftUI's
  /// environment carries (`mountayaScope(_:)`), with the view's own `strings` laid over its words,
  /// for that view alone, as `sdk-dart`'s and `sdk-kotlin`'s views lay theirs.
  ///
  /// Each of the view's words is named by its path, its section and its key joined by dots,
  /// `controls.zoomIn`, and replaces the scope's word there, a counted word's every form, so a
  /// `{count}` in it is filled; a path naming a section names no word. A path the view names no word
  /// for reads the scope's, the words an app's own scope states among them, so a view's words are
  /// layered over the app's. The words are laid over once each time SwiftUI draws the view, and not
  /// at all where it states none.
  @propertyWrapper
  struct ViewScope: DynamicProperty {
    @Environment(\.sharedScope) private var outer
    /// strings is the view's own words, by path, or nil for none.
    private let strings: [String: String]?
    /// laid is the scope with the view's words laid over it, as SwiftUI last read the environment,
    /// or nil where the view states none and reads the scope around it. It is held by reference, so
    /// a view carries one reference for it rather than a second scope beside the one around it.
    private var laid: Laid?

    /// Creates the scope of a view stating `strings`, its own words, where it states any.
    init(strings: [String: String]?) {
      self.strings = strings
    }

    /// wrappedValue is the scope the view reads its words in.
    var wrappedValue: ElementsScope {
      laid?.scope ?? outer.value
    }

    /// update lays the view's words over the scope around it, before SwiftUI draws the view.
    mutating func update() {
      if let strings, !strings.isEmpty {
        laid = Laid(scope: Self.scope(outer.value, strings: strings))
      } else {
        laid = nil
      }
    }

    /// Laid holds a scope with a view's words laid over it. It is Sendable: it holds one constant,
    /// the scope.
    final class Laid: Sendable {
      let scope: ElementsScope

      init(scope: ElementsScope) {
        self.scope = scope
      }
    }

    /// scope is `outer` with `strings` laid over its words, each at its path, or `outer` itself
    /// where `strings` names no word.
    static func scope(_ outer: ElementsScope, strings: [String: String]?) -> ElementsScope {
      guard let strings, !strings.isEmpty else { return outer }
      var words = outer.words
      for (path, word) in strings {
        lay(word, at: path.split(separator: ".", omittingEmptySubsequences: false)[...], in: &words)
      }
      return scopeOf(outer, stating: ElementsScopeStatement(words: .bySection(words)))
    }

    /// lay writes `word` at `path` in `words`: in place of a word, as a counted word's every form
    /// where a counted word stands there, and nowhere where a section does.
    private static func lay(
      _ word: String, at path: ArraySlice<Substring>, in words: inout [String: JSONValue]
    ) {
      guard let first = path.first else { return }
      let key = String(first)
      guard path.count > 1 else {
        switch words[key] {
        case .object(let forms)? where forms["other"] != nil:
          words[key] = .object(forms.mapValues { _ in .string(word) })
        case .object?:
          return
        default:
          words[key] = .string(word)
        }
        return
      }
      var section: [String: JSONValue] = [:]
      if case .object(let held)? = words[key] {
        section = held
      } else if words[key] != nil {
        return
      }
      lay(word, at: path.dropFirst(), in: &section)
      words[key] = .object(section)
    }
  }

  extension View {
    /// viewWords hands the parts of a view of the elements `scope`, the scope the view reads with its
    /// own `strings` laid over its words, where it states any, so every part of it speaks the view's
    /// words; a view that states none leaves the environment as it found it.
    func viewWords(_ scope: ElementsScope, stated strings: [String: String]?) -> some View {
      modifier(ViewWords(scope: scope, isStated: strings?.isEmpty == false))
    }
  }

  /// ViewWords hands the parts of the view it modifies `scope` where the view states words of its
  /// own, `isStated`, and leaves the environment as it found it where it states none: one modifier
  /// every view of the elements shares, rather than a wrapper of each view's own.
  private struct ViewWords: ViewModifier {
    let scope: ElementsScope
    let isStated: Bool

    func body(content: Content) -> some View {
      if isStated {
        content.environment(\.mountayaScope, scope)
      } else {
        content
      }
    }
  }
#endif
