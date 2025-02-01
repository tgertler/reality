import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/season.dart';
import '../../domain/repositories/season_repository.dart';
import '../sources/season_datasource.dart';

class SeasonRepositoryImpl implements SeasonRepository {
  final SeasonDataSource dataSource;
  final Logger _logger = getLogger('SeasonRepositoryImpl');

  SeasonRepositoryImpl(this.dataSource);

  @override
  Future<List<Season>> getSeasonsForShow(String showId) async {
    _logger.i('Fetching seasons for show with id: $showId');
    try {
      await Future.delayed(const Duration(seconds: 1));
      final seasons = dataSource.getSeasons();
      _logger.i('Seasons for show $showId received: $seasons');
      return seasons;
    } catch (e, stackTrace) {
      _logger.e('Error fetching seasons for show $showId', e, stackTrace);
      rethrow;
    }
  }
}