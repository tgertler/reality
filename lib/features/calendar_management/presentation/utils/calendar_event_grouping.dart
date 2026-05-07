class GroupedSequenceItem<T> {
  final T item;
  final bool isContinuation;
  final int indexInGroup;

  const GroupedSequenceItem({
    required this.item,
    this.isContinuation = false,
    this.indexInGroup = 0,
  });
}

List<GroupedSequenceItem<T>> groupConsecutiveByKey<T>(
  List<T> items,
  String? Function(T item) keySelector,
) {
  final groupedBuckets = <String, List<T>>{};
  final emittedKeys = <String>{};
  final result = <GroupedSequenceItem<T>>[];

  for (final item in items) {
    final key = keySelector(item)?.trim();
    if (key == null || key.isEmpty) {
      continue;
    }
    groupedBuckets.putIfAbsent(key, () => <T>[]).add(item);
  }

  for (final item in items) {
    final key = keySelector(item)?.trim();
    if (key == null || key.isEmpty) {
      result.add(GroupedSequenceItem<T>(item: item));
      continue;
    }

    if (!emittedKeys.add(key)) {
      continue;
    }

    final bucket = groupedBuckets[key] ?? const <dynamic>[];
    for (var i = 0; i < bucket.length; i++) {
      result.add(
        GroupedSequenceItem<T>(
          item: bucket[i] as T,
          isContinuation: i > 0,
          indexInGroup: i,
        ),
      );
    }
  }

  return result;
}
