import 'package:logger/logger.dart';

import '../../../../../core/utils/logger.dart';
import '../entities/attendee.dart';
import '../entities/creator.dart';
import '../entities/show.dart';
import '../repositories/creator_repository.dart';
import '../repositories/show_repository.dart';
import '../repositories/attendee_repository.dart';

class SearchShowsAndAttendeesUseCase {
  final ShowRepository showRepository;
  final AttendeeRepository attendeeRepository;
  final CreatorRepository creatorRepository;
  final Logger _logger = getLogger('SearchShowsAndAttendeesUseCase');

  SearchShowsAndAttendeesUseCase({
    required this.showRepository,
    required this.attendeeRepository,
    required this.creatorRepository,
  });

  Future<List<dynamic>> execute(String query) async {
    _logger.i('Starting search with query: $query');
    try {
      final shows = await showRepository.search(query);
      _logger.i('Shows received: $shows');

      final attendees = await attendeeRepository.search(query);
      _logger.i('Attendees received: $attendees');

      final creators = await creatorRepository.search(query);
      _logger.i('Creators received: $creators');

      final results = [
        ...shows.map((show) => {'type': 'show', 'data': show}),
        ...attendees.map((attendee) => {'type': 'attendee', 'data': attendee}),
        ...creators.map((creator) => {'type': 'creator', 'data': creator}),
      ];

      results.sort((a, b) {
        final aString = _searchLabel(a['data'] as Object);
        final bString = _searchLabel(b['data'] as Object);
        return aString.toLowerCase().compareTo(bString.toLowerCase());
      });

      _logger.i('Sorted results: $results');
      return results;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }

  String _searchLabel(Object data) {
    if (data is Show) return data.displayTitle;
    if (data is Attendee) return data.name ?? '';
    if (data is Creator) return data.name;
    return '';
  }
}