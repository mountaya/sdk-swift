import MountayaClient
import MountayaGeo

/// MapSurface is what a map engine asks of whatever draws it: MapLibre's map behind `MapView`, or
/// `ScriptedMapSurface`, which a test scripts. It reads the canvas the map is drawn on and moves its
/// camera; every rule of the map is the engine's, which hands a surface what to do and reads back
/// what only a renderer knows.
///
/// A surface tells the engine of what happens on it, a gesture, a frame, a failed request, a tile
/// or a style loaded and a camera at rest, through the engine's own methods for it. It is bound to
/// the main actor, as the engine is.
@MainActor
protocol MapSurface: AnyObject {
  /// zoomLimits is the renderer's own zoom limits: the floor under which a window may not reach and
  /// to which a released floor goes back, and the ceiling a released ceiling goes back to.
  var zoomLimits: ZoomBounds { get }

  /// projection is the renderer's projection as the map is drawn, from a position to the point of
  /// the canvas it is drawn at and back.
  var projection: ScreenProjection { get }

  /// move moves the camera to the members `target` states by `motion`, keeping every other member
  /// where the camera has it.
  func move(to target: CameraTarget, by motion: CameraMotion)

  /// frame fits the camera to `bounds`, a box in canonical form, with `fit`, within `window`, as
  /// `cameraForBounds` fits one on the canvas, facing north and keeping its pitch, and answers the
  /// camera it moves to, or nil where the canvas leaves no room.
  func frame(_ bounds: [Double], with fit: CameraFit, within window: ZoomBounds) -> CameraPose?

  /// holdsLayer tells whether the live style holds the layer `id`.
  func holdsLayer(_ id: String) -> Bool

  /// holdsSource tells whether the live style holds the source `id`.
  func holdsSource(_ id: String) -> Bool

  /// renderedFeatures answers the features the layers `layers` drew at `point` of the canvas,
  /// topmost first, each once per layer that drew it.
  func renderedFeatures(at point: [Double], in layers: [String]) -> [QueriedFeature]

  /// symbolLabels is the label of every symbol layer the live style holds, as its style wrote it,
  /// bottom to top, the map's own included.
  var symbolLabels: [SymbolLabel] { get }

  /// relabel sets the label of the symbol layer `id` to `label`, or back to the one its style wrote
  /// where `label` is nil.
  func relabel(_ id: String, to label: JSONValue?)

  /// creditedBaseSources is every source of the base map's style the map credits, in the order
  /// the renderer reads them, and whether a layer draws it at the camera's zoom.
  var creditedBaseSources: [CreditedSource] { get }

  /// mapMoved tells the surface that the view drawing the map now stands elsewhere in its window,
  /// laid out again or moved with no layout of its own, by a scroll view's scroll, a sheet's
  /// detent, an offset or a transform, so a renderer reads again what it reads off the window, the
  /// map's safe area (`sdk/SPEC.md` §15).
  func mapMoved()
}
