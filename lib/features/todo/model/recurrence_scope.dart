/// Which occurrences of a repeating task an edit or a delete applies to.
enum RecurrenceScope {
  /// Just the occurrence that was opened (the safe default).
  onlyThis('Only this item'),

  /// This occurrence and every one after it.
  thisAndFuture('This and all future items'),

  /// Every occurrence, past and future.
  all('All linked items');

  const RecurrenceScope(this.label);

  final String label;
}
