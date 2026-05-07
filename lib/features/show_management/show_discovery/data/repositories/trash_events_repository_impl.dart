import '../../domain/entities/trash_event.dart';
import '../../domain/repositories/trash_events_repository.dart';
import '../sources/trash_events_datasource.dart';

class TrashEventsRepositoryImpl implements TrashEventsRepository {
  final TrashEventsDataSource dataSource;

  TrashEventsRepositoryImpl(this.dataSource);

  @override
  Future<List<TrashEvent>> getTrashEventsForShow(String showId) async {
    final rows = await dataSource.getTrashEventsForShow(showId);
    return rows.map((r) => TrashEvent(
          id: r['id'] as String,
          title: r['title'] as String,
          description: r['description'] as String?,
          imageUrl: r['image_url'] as String?,
          location: r['location'] as String?,
          address: r['address'] as String?,
          organizer: r['organizer'] as String?,
          price: r['price'] as String?,
          externalUrl: r['external_url'] as String?,
          relatedShowId: r['related_show_id'] as String?,
          relatedSeasonId: r['related_season_id'] as String?,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.now(),
        )).toList();
  }
}
