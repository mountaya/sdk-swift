/// isWatermarkKeptClear answers whether nothing of a map's own may lay over the Mountaya
/// watermark's frame as the read of its organization stands, `read` (`geo.organization.watermark`,
/// `sdk/SPEC.md` §15). The frame is held from the moment the map is drawn, while the read waits too,
/// so a control stack, a panel, a readout or a marker's label kept clear of it does not move as the
/// mark lands, and it is released only once the read answers that the organization holds white
/// label, which draws no mark. A read that failed, that went one attempt's time budget with no
/// answer, or that a client holding no publishable key never makes holds it, since each draws the
/// mark.
///
/// Every part of the SDK's own interface keeps clear of the frame while it answers true, and a host
/// reads it over `MapEngine.organizationRead` to keep its own views clear of the mark too, by the
/// frame's extent, `watermarkWidth`, `watermarkHeight` and `watermarkInset`, or by
/// `watermarkClearance`. Every native SDK publishes it under this name.
public func isWatermarkKeptClear(_ read: OrganizationRead) -> Bool {
  read != .answered(whiteLabel: true)
}
