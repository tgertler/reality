import '../../domain/entities/creator.dart';
import '../../domain/entities/creator_event.dart';
import '../../domain/repositories/creator_events_repository.dart';
import '../sources/creator_events_datasource.dart';

class CreatorEventsRepositoryImpl implements CreatorEventsRepository {
  final CreatorEventsDataSource dataSource;

  CreatorEventsRepositoryImpl(this.dataSource);

  @override
  Future<List<CreatorEvent>> getCreatorEventsForShow(String showId) async {
    final rows = await dataSource.getCreatorEventsForShow(showId);
    return rows.map((r) {
      final creatorRaw = r['creators'];
      Creator? creator;
      if (creatorRaw is Map) {
        creator = Creator(
          id: creatorRaw['id'] as String? ?? '',
          name: creatorRaw['name'] as String? ?? '',
          avatarUrl: creatorRaw['avatar_url'] as String?,
          youtubeChannelUrl: creatorRaw['youtube_channel_url'] as String?,
          tiktokUrl: creatorRaw['tiktok_url'] as String?,
        );
      }
      return CreatorEvent(
        id: r['id'] as String,
        creatorId: r['creator_id'] as String,
        creator: creator,
        relatedShowId: r['related_show_id'] as String?,
        relatedSeasonId: r['related_season_id'] as String?,
        eventKind: r['event_kind'] as String? ?? 'reaction_video',
        youtubeUrl: r['youtube_url'] as String?,
        thumbnailUrl: r['thumbnail_url'] as String?,
        episodeNumber: r['episode_number'] as int?,
        title: r['title'] as String?,
        description: r['description'] as String?,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }
}
