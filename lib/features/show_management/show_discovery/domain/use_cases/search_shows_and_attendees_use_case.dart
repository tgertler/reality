import 'package:logger/logger.dart';

import '../../../../../core/utils/logger.dart';
import '../entities/attendee.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';
import '../repositories/attendee_repository.dart';

class SearchShowsAndAttendeesUseCase {
  final ShowRepository showRepository;
  final AttendeeRepository attendeeRepository;
  final Logger _logger = getLogger('SearchShowsAndAttendeesUseCase');

  SearchShowsAndAttendeesUseCase({
    required this.showRepository,
    required this.attendeeRepository,
  });

  Future<List<dynamic>> execute(String query) async {
    _logger.i('Starting search with query: $query');
    try {
      final shows = await showRepository.search(query);
      _logger.i('Shows received: $shows');

      final attendees = await attendeeRepository.search(query);
      _logger.i('Attendees received: $attendees');

      final results = [
        ...shows.map((show) => {'type': 'show', 'data': show}),
        ...attendees.map((attendee) => {'type': 'attendee', 'data': attendee}),
      ];

      results.sort((a, b) {
        final aData = a['data'];
        final bData = b['data'];
        final aString = aData is Show ? aData.title : (aData as Attendee).name;
        final bString = bData is Show ? bData.title : (bData as Attendee).name;
        return (bString ?? '').compareTo(aString ?? '');
      });

      _logger.i('Sorted results: $results');
      return results;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }
}