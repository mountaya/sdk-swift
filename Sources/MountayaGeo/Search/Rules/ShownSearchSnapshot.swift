/// shownSearchSnapshot is what a result list shows for the query `query` in its box
/// (`geo.search.typing-pause`): the search's own `snapshot` where it names that query, trimmed as a
/// round asks it, compared by its scalars, and `unanswered`, the stand-in for the query
/// (`unansweredSearchSnapshot(_:isLive:targets:)`), otherwise.
///
/// A round is asked once the typing pauses, and until then the search's snapshot answers the query
/// the pause last settled, or a round of an earlier one still in flight lands inside the pause; drawn
/// under the text now in the box, its rows would answer a question nobody is asking. So rows that
/// answer another query are never shown under this one.
func shownSearchSnapshot(_ snapshot: SearchSnapshot, query: String, unanswered: SearchSnapshot)
  -> SearchSnapshot
{
  sameText(snapshot.query, trimWhiteSpace(query)) ? snapshot : unanswered
}
