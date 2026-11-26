/// clearOfWatermark answers where `rect`, something of the map's own, stands once kept clear of the
/// watermark's `frame` inside `bounds`, the part of the map it keeps to, the map's safe area
/// (`sdk/SPEC.md` §15). It stands where it is while the two share no area. Otherwise it is moved by
/// the smallest move that clears the frame and keeps it inside `bounds`, the frame standing in the
/// safe area's top-left corner: down, its top at the frame's bottom, or right, its left edge at the
/// frame's right one, the shorter where both keep it inside and the move down where they are as
/// long. Where neither does, it stands with its top at the frame's bottom, and the map's edge cuts
/// it: the mark is never covered. With no frame, the map drawing no mark, it stands where it is.
///
/// A control stack stands as far from the frame as from the safe area's edges by handing the frame
/// grown by that room.
package func clearOfWatermark(_ rect: ScreenRect, frame: ScreenRect?, within bounds: ScreenRect)
  -> ScreenRect
{
  guard let frame, rect.overlaps(frame) else { return rect }
  let below = ScreenRect(x: rect.x, y: frame.maxY, width: rect.width, height: rect.height)
  let beside = ScreenRect(x: frame.maxX, y: rect.y, width: rect.width, height: rect.height)
  let fitsBelow = below.maxY <= bounds.maxY
  let fitsBeside = beside.maxX <= bounds.maxX
  if fitsBelow, fitsBeside {
    return below.y - rect.y <= beside.x - rect.x ? below : beside
  }
  return fitsBeside ? beside : below
}
