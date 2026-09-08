// Defensive ownership and value equality for DTOs and read-only hook contexts.
Object? freezeValue(Object? value) {
  if (value is Map) {
    if (value.keys.every((key) => key is String)) {
      return freezeFields(value.cast<String, Object?>());
    }
    return Map<Object?, Object?>.unmodifiable(
      value.map((k, v) => MapEntry(k, freezeValue(v))),
    );
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(freezeValue));
  return value;
}

Map<String, Object?> freezeFields(Map<String, Object?> fields) =>
    Map.unmodifiable(fields.map((k, v) => MapEntry(k, freezeValue(v))));

bool equalValues(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && equalValues(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!equalValues(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

int hashValue(Object? value) {
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map((e) => Object.hash(e.key, hashValue(e.value))),
    );
  }
  if (value is List) return Object.hashAll(value.map(hashValue));
  return value.hashCode;
}
