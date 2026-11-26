import MountayaClient
import MountayaGeo

/// relabelledBaseLabels is how a map's label language relabels its labels (`map.style.label-scope`):
/// each symbol layer of the base map, in the order given, with the label `relabelTextField` rewrites
/// its written label to for `language`, or nil where the label is left as written
/// (`geo.style.label-relabel`).
///
/// A layer the map placed itself, `isPlaced`, is never relabelled and is left out of the answer: it
/// draws from a source the base map knows nothing about, and its `name` is its own. A switch of
/// base map relabels the one it brings in, the map's own layers drawn again over it left as they
/// are.
func relabelledBaseLabels(
  _ labels: [SymbolLabel], isPlaced: (String) -> Bool, language: RestSchema.Language
) -> [(id: String, label: JSONValue?)] {
  labels.filter { !isPlaced($0.id) }.map { label in
    (label.id, relabelTextField(label.textField, language: language))
  }
}
