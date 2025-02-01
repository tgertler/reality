import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/repositories/show_repository.dart';
import '../sources/show_datasource.dart';

class ShowRepositoryImpl implements ShowRepository {
  final ShowDataSource dataSource;
  final Logger _logger = getLogger('ShowRepositoryImpl');

  ShowRepositoryImpl(this.dataSource);

  @override
  Future<List<Show>> getShows() async {
    _logger.i('Fetching all shows');
    try {
      await Future.delayed(const Duration(seconds: 1));
      final shows = dataSource.getShows();
      _logger.i('All shows received: $shows');
      return shows;
    } catch (e, stackTrace) {
      _logger.e('Error fetching all shows', e, stackTrace);
      rethrow;
    }
  }
}