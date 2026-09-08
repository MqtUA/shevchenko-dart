/// Validates the completeness and structure of the full fixture corpus.
void validateFullCorpus(Map<String, Object?> corpus) {
  if (corpus['trainingRows'] != 41092 ||
      corpus['generalRows'] != 99903 ||
      corpus['uniqueWords'] != 101302 ||
      corpus['calls'] != 1418228) {
    throw StateError('Unexpected full corpus counts');
  }
  final rows = corpus['rows'];
  final shards = corpus['shards'];
  if (rows is! List ||
      rows.length != corpus['uniqueWords'] ||
      shards is! List) {
    throw StateError('Missing full corpus rows or shards');
  }
  final words = <String>{};
  for (final row in rows) {
    if (row is! List ||
        row.length != 3 ||
        row[0] is! String ||
        row[1] is! num ||
        !(row[1] as num).isFinite ||
        (row[1] as num) < 0 ||
        (row[1] as num) > 1 ||
        !['noun', 'adjective'].contains(row[2]) ||
        !words.add(row[0] as String)) {
      throw StateError('Invalid or duplicate full corpus row');
    }
  }
  var next = 0;
  final digestPattern = RegExp(r'^[0-9a-f]{64}$');
  for (final shard in shards) {
    final expectedCount = rows.length - next < 1000 ? rows.length - next : 1000;
    if (shard is! Map ||
        shard['start'] != next ||
        expectedCount <= 0 ||
        shard['count'] != expectedCount ||
        shard['sha256'] is! String ||
        !digestPattern.hasMatch(shard['sha256'] as String)) {
      throw StateError(
        'Missing, overlapping or invalid full corpus shard at $next',
      );
    }
    next += expectedCount;
  }
  if (next != rows.length) {
    throw StateError('Full corpus shard coverage is incomplete');
  }
}
