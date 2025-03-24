import 'package:frontend/features/show_management/show_discovery/domain/entities/season.dart';
import 'package:frontend/features/show_management/show_discovery/domain/repositories/season_repository.dart';
import 'package:logger/logger.dart';

import '../../../../../core/utils/logger.dart';

class GetSeasonByIdUseCase {
  final SeasonRepository seasonRepository;
  final Logger _logger = getLogger('GetSeasonByIdUseCase');

  GetSeasonByIdUseCase({
    required this.seasonRepository,
  });

  Future<Season> execute(String id) async {
    _logger.i('Starting search with id: $id');
    try {
      final season = await seasonRepository.getSeasonById(id);
      _logger.i('Season received: $season');

      return season;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }
}