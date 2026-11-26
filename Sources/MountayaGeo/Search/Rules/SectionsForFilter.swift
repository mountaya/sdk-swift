import MountayaClient

/// sectionsForFilter is the sections of `sections`, each named by its search target and listed in
/// the order they render, that `filter` shows, in that same order: a list that renders its sections
/// in one order keeps it under every filter. A target the filter does not show, one this build does
/// not know among them, is left out.
public func sectionsForFilter(
  _ sections: [DataSchema.SearchTarget], filter: SearchFilter
) -> [DataSchema.SearchTarget] {
  let shown = filter.targets
  return sections.filter { shown.contains($0) }
}
