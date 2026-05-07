import 'dart:convert';

import '../../domain/entities/feed_item_entity.dart';

class FeedItem implements FeedItemEntity {
  @override
  final String id;
  @override
  final String itemType;
  @override
  final Map<String, dynamic> data;
  @override
  final DateTime feedTimestamp;
  @override
  final int priority;

  FeedItem({
    required this.id,
    required this.itemType,
    required this.data,
    required this.feedTimestamp,
    required this.priority,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic> parsedData;

    if (rawData is String) {
      try {
        parsedData = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {
        parsedData = {'value': rawData};
      }
    } else if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    } else if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    } else {
      parsedData = {'value': rawData?.toString() ?? ''};
    }

    DateTime parsedTimestamp;
    final timestamp = json['feed_timestamp'];

    if (timestamp is String) {
      parsedTimestamp = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      parsedTimestamp = timestamp;
    } else if (timestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return FeedItem(
      id: json['id']?.toString() ?? '',
      itemType: (json['item_type']?.toString().trim().isNotEmpty == true)
          ? json['item_type'].toString()
          : (parsedData['type']?.toString().trim().isNotEmpty == true)
              ? parsedData['type'].toString()
              : 'generic',
      data: parsedData,
      feedTimestamp: parsedTimestamp,
      priority: int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
    );
  }
}
