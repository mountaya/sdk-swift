#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaClient
  import MountayaGeo
  internal import SwiftUI

  /// LayersPanelTime is a layers panel's time section (`geo.layers.time-slider`): its caption, the
  /// sentence holding it where its track holds no instant, the thumb's readout and the slider, over
  /// the track `window` lays out, which the panel lays out afresh around its clock's reading each
  /// time it draws (`geo.layers.time-window`), so the window follows the clock with no timer of its
  /// own. It speaks the words of `words`, the panel's scope, held by one reference.
  ///
  /// The slider ticks every day of the track, the days `timeSliderTicks(_:)` labels carrying their
  /// words, fills its track from the stop of the clock's reading to its thumb, which stands at the
  /// instant the selection pins (`TimeSliderWindow.value(at:)`), and reads out the thumb's moment in
  /// the time zone the device keeps, `deviceTimeZone()`, never SwiftUI's `\.timeZone`, which an app
  /// may state for a view, and its distance from the clock's reading
  /// (`timeSliderReadout(_:at:)`). Let go of, whether dragged, stepped by an arrow key while it
  /// holds the keyboard's focus or adjusted by an assistive technology, it pins the instant of its
  /// stop through the selection, or none on the stop of the clock's reading
  /// (`timeSliderRelease(_:at:)`). A track of no instant holds it, under `layers.timeUnavailable`,
  /// and pins nothing.
  struct LayersPanelTime: View {
    let selection: LayersSelectionEngine
    let window: TimeSliderWindow
    let words: ViewScope.Laid

    /// dragged is the stop a drag holds the thumb at, nil while none is out.
    @State private var dragged: Int?
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let scope = words.scope
      let isHeld = window.start == nil
      let thumb = dragged ?? window.value(at: selection.state.instant)
      let readout = Self.readout(
        timeSliderReadout(window, at: thumb), in: scope, timeZone: deviceTimeZone())
      let _ = probe?.report("LayersPanelTime " + readout)
      let scheme = themeScheme(colorScheme)
      let ink = TrackInk(
        track: tokenColor(tokens.panelBorder, in: scheme),
        fill: tokenColor(isHeld ? tokens.controlFgDisabled : tokens.accent, in: scheme),
        tick: tokenColor(tokens.dimmed, in: scheme), ground: tokenColor(tokens.panelBg, in: scheme))
      var ticks: [(value: Int, word: String?)] = []
      for tick in timeSliderTicks(window) {
        ticks.append((tick.value, tick.word.map { scope.word($0) }))
      }
      let caption = Self.caption(in: scope, hasKeyboard: HardwareKeyboard.isConnected)
      return VStack(alignment: .leading, spacing: 6) {
        // A track of no instant holds the slider, which says so above its caption.
        Text(verbatim: isHeld ? scope.word("layers.timeUnavailable") + "\n" + caption : caption)
          .font(.caption).foregroundStyle(ink.tick)
        Text(verbatim: readout).font(.footnote.monospacedDigit())
        GeometryReader { proxy in
          let width = proxy.size.width
          Canvas { context, size in
            Self.draw(
              in: &context, size: size, thumb: thumb, window: window, ticks: ticks, ink: ink)
          }
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { drag in
                if !isHeld {
                  dragged = Self.value(at: drag.location.x, width: width, maxValue: window.maxValue)
                }
              }
              .onEnded { drag in
                release(Self.value(at: drag.location.x, width: width, maxValue: window.maxValue))
              })
        }
        .frame(height: Self.height)
        .focusRing(cornerRadius: 6)
        .focusable(!isHeld)
        .focusEffectDisabled()
        .onKeyPress { press in
          guard let step = Self.step(of: press.key) else { return .ignored }
          release(Self.stepped(thumb, by: step, maxValue: window.maxValue))
          return .handled
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: scope.word("layers.time")))
        .accessibilityValue(Text(verbatim: readout))
        .accessibilityAdjustableAction { direction in
          release(
            Self.stepped(thumb, by: direction == .increment ? 1 : -1, maxValue: window.maxValue))
        }
      }
    }

    /// release lets the thumb go on the stop `value`, which pins its instant, or none.
    private func release(_ value: Int) {
      dragged = nil
      Self.release(value, of: window, to: selection)
    }

    /// TrackInk is what a slider is drawn in: its track, its fill and thumb, its ticks and their
    /// words, and the ring around its thumb.
    struct TrackInk {
      let track: Color
      let fill: Color
      let tick: Color
      let ground: Color
    }

    /// height is the slider's height, its track and the words of its ticks, the platform's touch
    /// target and more, in points.
    static var height: CGFloat { 48 }

    /// inset is how far the track's ends stand in from the slider's, the thumb's radius and its
    /// ring, so the thumb is drawn whole at either end.
    static var inset: CGFloat { 11 }

    /// draw draws the slider on `context`: the track across its width, the fill from the stop of the
    /// clock's reading to `thumb`, each tick and its word, and the thumb.
    static func draw(
      in context: inout GraphicsContext, size: CGSize, thumb: Int, window: TimeSliderWindow,
      ticks: [(value: Int, word: String?)], ink: TrackInk
    ) {
      let span = max(size.width - 2 * inset, 0)
      func x(_ value: Int) -> CGFloat {
        inset + span * CGFloat(value) / CGFloat(max(window.maxValue, 1))
      }
      let line: CGFloat = 16
      context.fill(
        Path(roundedRect: CGRect(x: inset, y: line - 2, width: span, height: 4), cornerRadius: 2),
        with: .color(ink.track))
      let from = x(window.nowValue)
      let to = x(thumb)
      context.fill(
        Path(
          roundedRect: CGRect(x: min(from, to), y: line - 2, width: abs(to - from), height: 4),
          cornerRadius: 2), with: .color(ink.fill))
      for tick in ticks {
        let at = x(tick.value)
        context.fill(
          Path(CGRect(x: at - 0.5, y: line - 7, width: 1, height: 14)), with: .color(ink.tick))
        if let word = tick.word {
          context.draw(
            Text(verbatim: word).font(.caption2).foregroundColor(ink.tick),
            at: CGPoint(x: at, y: line + 10), anchor: .top)
        }
      }
      let knob = Path(ellipseIn: CGRect(x: to - 9, y: line - 9, width: 18, height: 18))
      context.fill(knob, with: .color(ink.fill))
      context.stroke(knob, with: .color(ink.ground), lineWidth: 2)
    }

    /// value is the stop a point `x` points along a slider `width` wide falls nearest, held to the
    /// track from 0 to `maxValue`.
    static func value(at x: CGFloat, width: CGFloat, maxValue: Int) -> Int {
      let span = width - 2 * inset
      guard span > 0 else { return 0 }
      let value = ((x - inset) / span * CGFloat(maxValue)).rounded()
      return Int(min(max(value, 0), CGFloat(maxValue)))
    }

    /// step is the stops an arrow key moves the thumb by, one an hour, and nil for any other key.
    static func step(of key: KeyEquivalent) -> Int? {
      switch key {
      case .leftArrow, .downArrow: -1
      case .rightArrow, .upArrow: 1
      default: nil
      }
    }

    /// stepped is the stop `delta` stops on from `thumb`, held to the track from 0 to `maxValue`.
    static func stepped(_ thumb: Int, by delta: Int, maxValue: Int) -> Int {
      min(max(thumb + delta, 0), maxValue)
    }

    /// release pins what a release of the thumb on the stop `value` of `window`'s track commits
    /// (`timeSliderRelease(_:at:)`) through `selection`: the stop's instant, or none on the stop of
    /// the clock's reading, and nothing on a track of no instant.
    static func release(
      _ value: Int, of window: TimeSliderWindow, to selection: LayersSelectionEngine
    ) {
      guard let released = timeSliderRelease(window, at: value) else { return }
      selection.setInstant(released.pin)
    }

    /// caption is what the section says under its heading, in the words of `scope`: what the slider
    /// drives, `layers.timeHint`, how a keyboard moves it, `layers.timeKeyboard`, only where
    /// `hasKeyboard` says a hardware keyboard is at hand, and the zone its times are shown in,
    /// `layers.timeNote`.
    static func caption(in scope: ElementsScope, hasKeyboard: Bool) -> String {
      let keys = hasKeyboard ? scope.word("layers.timeKeyboard") + " " : ""
      return scope.word("layers.timeHint") + " " + keys + scope.word("layers.timeNote")
    }

    /// readout is what the thumb reads in the words of `scope`: the instant its stop stands for,
    /// written by the locale services as the scope's locale writes a weekday, a day, a month, an
    /// hour and a minute in the time zone `timeZone` names, then ` · `, then its offset's word,
    /// counted where it counts hours or days; the offset alone where the stop stands for no
    /// instant, or where the locale services know no zone of that name, the moment left out
    /// rather than written in UTC or as an ISO string.
    static func readout(_ readout: TimeSliderReadout, in scope: ElementsScope, timeZone: String)
      -> String
    {
      var offset = scope.word(readout.word)
      // A counted word's path is its section's key, a dot, and its own key.
      if let count = readout.count, let dot = readout.word.firstIndex(of: "."),
        case .object(let section)? = scope.words[String(readout.word[..<dot])],
        let word = section[String(readout.word[readout.word.index(after: dot)...])],
        let counted = countedText(word, count: count, language: scope.language)
      {
        offset = counted
      }
      guard let instant = readout.instant,
        let moment = localeMomentText(instant, languageTag: scope.locale, timeZone: timeZone)
      else { return offset }
      return moment + " · " + offset
    }
  }
#endif
