import 'package:frontend/features/show_management/show_discovery/domain/repositories/season_repository.dart';
import 'package:logger/logger.dart';

import '../../../../../core/utils/logger.dart';
import '../entities/attendee.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';
import '../repositories/attendee_repository.dart';

class GetSeasonsByShowUseCase {
  final SeasonRepository seasonRepository;
  final Logger _logger = getLogger('GetSeasonsByShowUseCase');

  GetSeasonsByShowUseCase({
    required this.seasonRepository,
  });

  Future<List<dynamic>> execute(String showId) async {
    _logger.i('Starting search with query: $showId');
    try {
      final seasons = await seasonRepository.getSeasonsByShow(showId);
      _logger.i('Shows received: $seasons');

      seasons.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

      _logger.i('Sorted results: $seasons');
      return seasons;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }
}
