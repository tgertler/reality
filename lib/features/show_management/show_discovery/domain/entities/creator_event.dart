import 'creator.dart';

/// event_kind values: reaction_video | reaction_premiere | livestream | recap
class CreatorEvent {
  final String id;
  final String creatorId;
  final Creator? creator;
  final String? relatedShowId;
  final String? relatedSeasonId;
  final String eventKind;
  final String? youtubeUrl;
  final String? thumbnailUrl;
  final int? episodeNumber;
  final String? title;
  final String? description;
  final DateTime createdAt;

  const CreatorEvent({
    required this.id,
    required this.creatorId,
    this.creator,
    this.relatedShowId,
    this.relatedSeasonId,
    required this.eventKind,
    this.youtubeUrl,
    this.thumbnailUrl,
    this.episodeNumber,
    this.title,
    this.description,
    required this.createdAt,
  });

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    final creatorName = creator?.name ?? '';
    if (episodeNumber != null) return '$creatorName – Episode $episodeNumber';
    return creatorName;
  }

  String get kindLabel {
    switch (eventKind) {
      case 'reaction_video':
        return 'Reaction';
      case 'reaction_premiere':
        return 'Reaction Premiere';
      case 'livestream':
        return 'Livestream';
      case 'recap':
        return 'Recap';
      default:
        return eventKind;
    }
  }
}
