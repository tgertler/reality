import '../../domain/entities/show_social_tag.dart';
import '../../domain/entities/show_social_video.dart';
import '../../domain/repositories/show_social_repository.dart';
import '../sources/show_social_datasource.dart';

class ShowSocialRepositoryImpl implements ShowSocialRepository {
  final ShowSocialDataSource dataSource;

  ShowSocialRepositoryImpl(this.dataSource);

  @override
  Future<List<ShowSocialTag>> getTagsForShow(String showId) async {
    final rows = await dataSource.getTagsForShow(showId);
    return rows.map((r) => ShowSocialTag(
      id: r['id'] as String,
      showId: r['show_id'] as String,
      platform: r['platform'] as String? ?? 'tiktok',
      tag: r['tag'] as String,
      displayTag: r['display_tag'] as String,
      isPrimary: r['is_primary'] as bool? ?? false,
      priority: (r['priority'] as int?) ?? 10,
    )).toList();
  }

  @override
  Future<List<ShowSocialVideo>> getVideosForShow(String showId) async {
    final rows = await dataSource.getVideosForShow(showId);
    return rows.map((r) => ShowSocialVideo(
      id: r['id'] as String,
      showId: r['show_id'] as String,
      platform: r['platform'] as String? ?? 'tiktok',
      videoUrl: r['video_url'] as String,
      embedHtml: r['embed_html'] as String?,
      priority: (r['priority'] as int?) ?? 10,
    )).toList();
  }
}
