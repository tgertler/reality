import 'package:frontend/core/utils/logger.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/repositories/attendee_repository.dart';
import '../sources/attendee_data_source.dart';

class AttendeeRepositoryImpl implements AttendeeRepository {
  final AttendeeDataSource dataSource;
  final _logger = getLogger('AttendeeRepositoryImpl');

  AttendeeRepositoryImpl(this.dataSource);

  @override
  Future<List<Attendee>> search(String query) async {
    _logger.i('Starting search for attendees with query: $query');
    try {
      final response = await dataSource.search(query);
      _logger.i('Received response: $response');

      final mappedResults = response
        .map((json) => Attendee(
          id: json['id'].toString(), 
          name: json['name'], 
          bio: json['bio']
        ))
        .toList();

      _logger.i('Filtered results: $mappedResults');
      return mappedResults;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }

   @override
  Future<Attendee> getAttendeeById(String id) async {
    _logger.i('Starting getById for attendee with id: $id');
    try {
      final response = await dataSource.getShowById(id);
      _logger.i('Received response: $response');

      final attendee = Attendee(
        id: response?['id'].toString() ?? '',
        name: response?['name'] ?? '',
        bio: response?['bio'] ?? '',
      );

      _logger.i('Fetched attendee: $attendee');
      return attendee;
    } catch (e, stackTrace) {
      _logger.e('Error during getById', e, stackTrace);
      rethrow;
    }
  }
  
}
