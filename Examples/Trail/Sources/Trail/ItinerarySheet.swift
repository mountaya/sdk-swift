import MountayaElements
import MountayaGeo
import MountayaNavigation
import SwiftUI

/// ItinerarySheet is the bottom of Trail's screen: Replay and Start, or the navigation as it runs
/// and Stop, over the itinerary's elevation profile, and, opened by its handle, its segment and
/// waypoint tables, which scroll inside the height `MapScreen` leaves the sheet under the frame
/// the watermark stands in, `MapScreen.aboveTheSheet`. It is found by its accessibility
/// identifier, `trail.sheet`.
struct ItinerarySheet: View {
  @Bindable var model: AppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        model.isExpanded.toggle()
      } label: {
        Capsule()
          .fill(Color(uiColor: .tertiaryLabel))
          .frame(width: 40, height: 5)
          .frame(maxWidth: .infinity, minHeight: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Words.details)

      NavigationPanel(model: model)

      // trail: trail.profile
      ItineraryProfile(
        itineraryId: model.itineraryId, cache: model.itineraries, map: model.map,
        units: model.units, parts: [.amenities, .tooltip, .distanceAxis, .navigator],
        formatCutoffAt: model.cutoff
      )
      .frame(height: 180)
      .accessibilityIdentifier("trail.profile")

      if model.isExpanded {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            ItinerarySegmentTable(
              itineraryId: model.itineraryId, cache: model.itineraries, map: model.map,
              units: model.units)
            ItineraryWaypointTable(
              itineraryId: model.itineraryId, cache: model.itineraries, map: model.map,
              units: model.units, formatCutoffAt: model.cutoff)
          }
        }
        .frame(maxHeight: 360)
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 12)
    .background(
      Color(uiColor: .systemBackground),
      in: UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16, style: .continuous)
    )
    .background(Color(uiColor: .systemBackground).ignoresSafeArea(edges: .bottom))
    .shadow(color: .black.opacity(0.15), radius: 12)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("trail.sheet")
  }
}

/// NavigationPanel is what the sheet shows of a navigation: Replay and Start while none runs; the
/// instruction of the maneuver ahead, what is left of the route, and Stop while one does; and the
/// arrival, with Stop, once the traveller has arrived. Each is found by its accessibility
/// identifier.
struct NavigationPanel: View {
  @Bindable var model: AppModel

  var body: some View {
    if let run = model.run {
      let state = run.engine.state
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          if state.status == .arrived {
            // trail: trail.stop
            Text(Words.arrived)
              .font(.headline)
              .accessibilityIdentifier("trail.arrived")
          } else if let instruction = model.instruction(state) {
            // trail: trail.progress
            Text(instruction)
              .font(.headline)
              .accessibilityIdentifier("trail.instruction")
            if let progress = model.progress(state) {
              Text(progress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Button(Words.stop) { model.stop() }
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("trail.stop")
      }
      .frame(minHeight: 48)
    } else {
      HStack(spacing: 12) {
        // trail: trail.location
        Text(Words.replay)
          .accessibilityHidden(true)
        Toggle(Words.replay, isOn: $model.isReplaying)
          .labelsHidden()
          .accessibilityIdentifier("trail.replay")
        Spacer()
        // trail: trail.navigation
        Button(Words.start) { model.start() }
          .buttonStyle(.borderedProminent)
          .disabled(model.itineraryId == nil)
          .accessibilityIdentifier("trail.start")
      }
      .frame(minHeight: 48)
    }
  }
}
