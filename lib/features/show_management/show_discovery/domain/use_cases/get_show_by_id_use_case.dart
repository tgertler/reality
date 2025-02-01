import 'package:logger/logger.dart';

import '../../../../../core/utils/logger.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';

class GetShowByIdUseCase {
  final ShowRepository showRepository;
  final Logger _logger = getLogger('GetShowByIdUseCase');

  GetShowByIdUseCase({
    required this.showRepository,
  });

  Future<Show> execute(String id) async {
    _logger.i('Starting search with id: $id');
    try {
      final show = await showRepository.getShowById(id);
      _logger.i('Show received: $show');

      return show;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }
}