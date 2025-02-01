import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/repositories/show_repository.dart';
import '../sources/show_data_source.dart';

class ShowRepositoryImpl implements ShowRepository {
  final ShowDataSource dataSource;
  final Logger _logger = getLogger('ShowRepositoryImpl');

  ShowRepositoryImpl(this.dataSource);

  @override
  Future<List<Show>> search(String query) async {
    _logger.i('Starting search for shows with query: $query');
    try {
      final response = await dataSource.search(query);
      _logger.i('Received response: $response');

      final filteredResults = response
        .map((json) => Show(
          id: json['id'].toString(), 
          title: json['title'], 
          description: json['description']
        ))
        .toList();

      _logger.i('Filtered results: $filteredResults');
      return filteredResults;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Show> getShowById(String id) async {
    _logger.i('Starting getById for show with id: $id');
    try {
      final response = await dataSource.getShowById(id);
      _logger.i('Received response: $response');

      final show = Show(
        id: response?['id'].toString() ?? '',
        title: response?['title'] ?? '',
        description: response?['description'] ?? '',
      );

      _logger.i('Fetched show: $show');
      return show;
    } catch (e, stackTrace) {
      _logger.e('Error during getById', e, stackTrace);
      rethrow;
    }
  }
}