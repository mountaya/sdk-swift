import Foundation

/// deviceTimeZone is the identifier of the time zone the device keeps, as the system sets it and
/// read afresh each time: never SwiftUI's `\.timeZone`, which an app may state for a view, nor a
/// default an app states for its process, so a readout writes a moment in the device's own zone
/// (`sdk/SPEC.md` §15) and a time slider's thumb reads its moment there
/// (`geo.layers.time-readout`), as every SDK's do. The system answers it at once, so no moment is
/// ever written in another zone while the device's is read.
func deviceTimeZone() -> String {
  NSTimeZone.resetSystemTimeZone()
  return NSTimeZone.system.identifier
}
