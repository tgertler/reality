import 'package:logger/logger.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/repositories/content_repository.dart';
import '../sources/content_data_source.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentDataSource dataSource;
  final Logger _logger = getLogger('ContentRepositoryImpl');

  ContentRepositoryImpl(this.dataSource);

  @override
  Future<void> addShow(Show show) async {
    _logger.i('Adding show: $show');
    try {
      await dataSource.addShow(show);
      _logger.i('Show added successfully');
    } catch (e, stackTrace) {
      _logger.e('Error adding show', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addSeason(Season season) async {
    _logger.i('Adding season: $season');
    try {
      await dataSource.addSeason(season);
      _logger.i('Season added successfully');
      await generateCalendarEvents(season);
    } catch (e, stackTrace) {
      _logger.e('Error adding season', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addAttendee(Attendee attendee) async {
    _logger.i('Adding attendee: $attendee');
    try {
      await dataSource.addAttendee(attendee);
      _logger.i('Attendee added successfully');
    } catch (e, stackTrace) {
      _logger.e('Error adding attendee', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> generateCalendarEvents(Season season) async {
    _logger.i('Generating calendar events for season: $season');
    try {
      await dataSource.generateCalendarEvents(season);
      _logger.i('Calendar events generated successfully');
    } catch (e, stackTrace) {
      _logger.e('Error generating calendar events', e, stackTrace);
      rethrow;
    }
  }
}