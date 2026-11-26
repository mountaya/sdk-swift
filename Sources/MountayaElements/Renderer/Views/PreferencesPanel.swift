#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// PreferencesPanel is the units and language picker (`geo.units.preference-choices`): the length
  /// system, the form a travel rate takes, the slope notation, the temperature scale and the label
  /// language, in that order, each option in the order the contract lists it, a unit by its word
  /// and a language by its own name, which a reader finds fastest written the way they write it.
  ///
  /// It holds no set of its own: units are the app's concern, read by surfaces a picker cannot see,
  /// so `preferences` is the app's, and a press writes the whole set back with one preference
  /// changed. A language is the map's concern too, so a press on one also relabels `map`
  /// (`MapEngine.setLabelLanguage(_:)`). A language is ticked as the map reads the set's tag, so
  /// one holding `fr-CA` ticks French. Its words are the scope's `preferences` section
  /// (`mountayaScope(_:)`), each replaced by `strings` where it names the word's path.
  public struct PreferencesPanel: View {
    private let preferences: Binding<UnitPreferences>
    private let map: MapEngine?

    @ViewScope private var scope: ElementsScope

    /// Creates the picker over `preferences`, a press on a language relabelling `map`, its words
    /// replaced by `strings` where it names theirs.
    public init(
      preferences: Binding<UnitPreferences>, map: MapEngine? = nil,
      strings: [String: String]? = nil
    ) {
      self.preferences = preferences
      self.map = map
      _scope = ViewScope(strings: strings)
    }

    /// body is the five preferences, each under its heading.
    public var body: some View {
      PanelSurface(title: scope.word("controls.preferences")) {
        ForEach(preferenceChoices(preferences.wrappedValue), id: \.field) { choice in
          VStack(alignment: .leading, spacing: 6) {
            PanelHeading(text: scope.word("preferences.\(choice.field.rawValue)"))
            LazyVGrid(columns: Self.columns, spacing: 8) {
              ForEach(choice.options, id: \.value) { option in
                PreferenceCard(
                  label: Self.label(option.label, in: scope), isChecked: option.isChecked,
                  action: { Self.select(option.value, in: preferences, relabelling: map) })
              }
            }
          }
        }
      }
    }

    /// select carries out a press on the option `value`: the set it asks for written to
    /// `preferences`, and the map relabelled where it is a language.
    /// columns is the grid each choice's options stand in, two cards to a row sharing the panel's
    /// width (`geo.panels.layout`).
    private static let columns = Array(
      repeating: GridItem(.flexible(), spacing: 8),
      count: ElementLayout.panelPreferenceCardColumns)

    static func select(
      _ value: PreferenceValue, in preferences: Binding<UnitPreferences>,
      relabelling map: MapEngine?
    ) {
      let press = preferencePress(preferences.wrappedValue, pressing: value)
      preferences.wrappedValue = press.next
      if let relabel = press.relabel {
        map?.setLabelLanguage(relabel)
      }
    }

    /// label is the text an option is labelled with: a word of the scope's `preferences` section,
    /// or a language's own name.
    static func label(_ label: PreferenceLabel, in scope: ElementsScope) -> String {
      switch label {
      case .word(let word): scope.word("preferences.\(word)")
      case .name(let name): name
      }
    }
  }

  /// PreferenceCard is one option of a preferences panel drawn as a card, as the embed's panel
  /// draws it (`geo.panels.layout`): its label in a bordered box `panel-preference-card-height`
  /// high, the border `accent` and two points wide while the option is ticked, pressed as a whole
  /// and read by assistive technologies as selected while it is.
  struct PreferenceCard: View {
    let label: String
    let isChecked: Bool
    let action: () -> Void

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("PreferenceCard " + label)
      Button(action: action) {
        Text(verbatim: label)
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .padding(6)
          .frame(maxWidth: .infinity, minHeight: ElementLayout.panelPreferenceCardHeight)
          .overlay(
            RoundedRectangle(cornerRadius: 6).strokeBorder(
              tokenColor(
                isChecked ? tokens.accent : tokens.panelBorder, in: themeScheme(colorScheme)),
              lineWidth: isChecked ? 2 : 1)
          )
          .contentShape(Rectangle())
      }
      .buttonStyle(ElementButtonStyle())
      .focusEffectDisabled()
      .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
  }
#endif
