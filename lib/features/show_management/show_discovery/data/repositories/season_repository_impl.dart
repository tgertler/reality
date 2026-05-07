import 'package:frontend/features/show_management/show_discovery/data/sources/season_data_source.dart';
import 'package:frontend/features/show_management/show_discovery/domain/repositories/season_repository.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/season.dart';
import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';

class SeasonRepositoryImpl implements SeasonRepository {
  final SeasonDataSource dataSource;
  final Logger _logger = getLogger('SeasonRepositoryImpl');

  SeasonRepositoryImpl(this.dataSource);

  @override
  Future<List<Season>> getSeasonsByShow(String showId) async {
    _logger.i('Starting searching seasons for show: $showId');
    try {
      final response = await dataSource.getSeasonsByShow(showId);
      _logger.i('Received response: $response');

      final filteredResults = response.map((json) {
        final season = Season(
          id: json['id'],
          showId: json['show_id'],
          seasonNumber: json['season_number'],
          releaseFrequency: json['release_frequency'],
          totalEpisodes: json['total_episodes'],
          streamingOption: json['streaming_option'],
            streamingReleaseDate: DateTime.parse(json['streaming_release_date']),
        );
        return season;
      }).toList();

      _logger.i('Filtered results: $filteredResults');
      return filteredResults;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Season> getSeasonById(String id) async {
    _logger.i('Starting getById for season with id: $id');
    try {
      final response = await dataSource.getSeasonById(id);
      _logger.i('Received response: $response');

      final season = Season(
        id: response?['id'],
        showId: response?['show_id'],
        seasonNumber: response?['season_number'],
        releaseFrequency: response?['release_frequency'],
        totalEpisodes: response?['total_episodes'],
        streamingOption: response?['streaming_option'],
        streamingReleaseDate: DateTime.parse(response?['streaming_release_date']),
      );

      _logger.i('Fetched season: $season');
      return season;
    } catch (e, stackTrace) {
      _logger.e('Error during getById', e, stackTrace);
      rethrow;
    }
  }
}
