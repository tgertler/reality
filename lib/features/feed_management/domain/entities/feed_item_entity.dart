abstract class FeedItemEntity {
  String get id;
  String get itemType;
  Map<String, dynamic> get data;
  DateTime get feedTimestamp;
  int get priority;
}
