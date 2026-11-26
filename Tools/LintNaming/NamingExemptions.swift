/// NamingExemptions is the list of names the naming law lets through.
///
/// An exemption is keyed by the declaration's qualified name and valued by the sentence that
/// justifies it. The gate counts them, and fails on one that names nothing the tree declares.
enum NamingExemptions {
  static let table: [String: String] = [
    "MountayaError":
      "A bare `Error` would shadow the standard library's protocol in every file that imports "
      + "this SDK (SPEC.md section 5).",
    "isAPIError(_:)":
      "It asks whether an error is an `APIError`, as `isMountayaError(_:)` asks whether it is a "
      + "`MountayaError`, and a member that names a type spells the type as it is declared "
      + "(SPEC.md section 5).",
    "Mountaya.init(credential:language:baseUrls:retry:timeout:onResponse:exchange:clock:random:wallClock:)":
      "`onResponse` is the contract's own name for the hook (`sdk/SPEC.md` section 2), the one "
      + "every SDK publishes; a response is what the hook is told of, not a gesture it handles "
      + "(SPEC.md section 4).",
    "SystemExchange.Deliveries.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)":
      "Foundation's `URLSessionTaskDelegate` names the requirement, and a delegate that refuses "
      + "a redirect implements it under that name or is never asked (SPEC.md section 4).",
  ]

  /// guarded is the exemptions of declarations an iOS trait guards, which only the iOS
  /// simulator's graph holds, so a host that reads no such graph holds none of them stale.
  static let guarded: [String: String] = [
    "MapCanvas.makeUIView(context:)":
      "SwiftUI's `UIViewRepresentable` names the requirement, and a view that draws a UIKit view "
      + "implements it under that name or draws nothing (SPEC.md section 8).",
    "MapCanvas.updateUIView(_:context:)":
      "SwiftUI's `UIViewRepresentable` names the requirement, which SwiftUI calls whenever the "
      + "view is drawn again (SPEC.md section 8).",
    "MapCanvas.dismantleUIView(_:coordinator:)":
      "SwiftUI's `UIViewRepresentable` names the requirement, which SwiftUI calls as it lets the "
      + "view go, so the engine hears that no view draws its map (SPEC.md section 8).",
    "WindowProbe.makeUIView(context:)":
      "SwiftUI's `UIViewRepresentable` names the requirement, and a probe that reads its window "
      + "through a UIKit view implements it under that name or reads nothing (SPEC.md section 8).",
    "WindowProbe.updateUIView(_:context:)":
      "SwiftUI's `UIViewRepresentable` names the requirement, which SwiftUI calls as the view the "
      + "probe marks moves, so it reads its window again (SPEC.md section 8).",
    "MapRenderer.mapView(_:tileDidTriggerAction:x:y:z:wrap:overscaledZ:sourceID:)":
      "MapLibre's `MLNMapViewDelegate` names the requirement, `sourceID` included, and a delegate "
      + "that hears a source's tile load implements it under that name or is never told "
      + "(SPEC.md section 8).",
    "MapRequestHook.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)":
      "Foundation's `URLSessionTaskDelegate` names the requirement, and the session a map's "
      + "requests leave on hears a redirect under that name or follows it with every header "
      + "(SPEC.md section 8).",
  ]
}
