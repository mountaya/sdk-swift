import MountayaClient

/// collectionRow is the row a `collection` renders as for `query`: identified `collection:` then
/// its id, titled by its name, its second line its count of itineraries for the surface to
/// pluralize. Picking it opens the collection with its own fields, so an editor shows them at once;
/// one with no description carries `nil`, as the API sends it.
///
/// `nil` where it carries no id.
public func collectionRow(_ collection: DataSchema.CollectionSearchResult, query: String)
  -> SearchRow?
{
  collectionRow(collection, folded: foldedQuery(query))
}

/// collectionRow is the row `collection` renders as for a query already folded,
/// `foldedQuery(_:)`, as a round builds every row of its answers against one fold of its query.
func collectionRow(
  _ collection: DataSchema.CollectionSearchResult, folded query: [Unicode.Scalar]
) -> SearchRow? {
  guard let id = collection.id else { return nil }
  let title = collection.name ?? ""
  return SearchRow(
    id: "collection:\(id)", title: title, matched: highlightRanges(title, folded: query),
    secondary: .count(itineraries: collection.count?.itineraries), activities: [],
    payload: .collection(
      collectionId: id, name: collection.name, description: collection.description,
      isPrivate: collection.isPrivate))
}
