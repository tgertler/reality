import 'package:frontend/core/utils/logger.dart';

import '../../domain/entities/creator.dart';
import '../../domain/repositories/creator_repository.dart';
import '../sources/creator_data_source.dart';

class CreatorRepositoryImpl implements CreatorRepository {
  final CreatorDataSource dataSource;
  final _logger = getLogger('CreatorRepositoryImpl');

  CreatorRepositoryImpl(this.dataSource);

  @override
  Future<List<Creator>> search(String query) async {
    _logger.i('Starting search for creators with query: $query');
    final response = await dataSource.search(query);

    return response
        .map((json) => Creator(
              id: json['id'].toString(),
              name: (json['name'] as String?) ?? '',
              description: json['description'] as String?,
              avatarUrl: json['avatar_url'] as String?,
              youtubeChannelUrl: json['youtube_channel_url'] as String?,
              instagramUrl: json['instagram_url'] as String?,
              tiktokUrl: json['tiktok_url'] as String?,
            ))
        .toList();
  }
}