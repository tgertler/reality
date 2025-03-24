import '../entities/show.dart';
import '../entities/season.dart';
import '../entities/attendee.dart';

abstract class ContentRepository {
  Future<void> addShow(Show show);
  Future<void> addSeason(Season season);
  Future<void> addAttendee(Attendee attendee);
  Future<void> generateCalendarEvents(Season season);
}