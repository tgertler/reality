import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/entities/calendar_event.dart';

class ContentDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('ContentDataSource');

  ContentDataSource(this.supabaseClient);

  Future<void> addShow(Show show) async {
    _logger.i('Adding show: ${show.toJson()}');
<<<<<<< HEAD
    final response = await supabaseClient.from('shows').insert(show.toJson());
=======
    final response = await supabaseClient
        .schema('show_management')
        .from('shows')
        .insert(show.toJson());
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

    _logger.i('Show added successfully');
  }

  Future<void> addSeason(Season season) async {
    _logger.i('Adding season: ${season.toJson()}');
<<<<<<< HEAD
    final response =
        await supabaseClient.from('seasons').insert(season.toJson());
=======
    final response = await supabaseClient
        .schema('show_management')
        .from('seasons')
        .insert(season.toJson());
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

    _logger.i('Season added successfully');
  }

  Future<void> addAttendee(Attendee attendee) async {
    _logger.i('Adding attendee: ${attendee.toJson()}');
<<<<<<< HEAD
    final response =
        await supabaseClient.from('attendees').insert(attendee.toJson());
=======
    final response = await supabaseClient
        .schema('show_management')
        .from('attendees')
        .insert(attendee.toJson());
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

    _logger.i('Attendee added successfully');
  }

  Future<void> generateCalendarEvents(Season season) async {
    _logger.i('Generating calendar events for season: ${season.toJson()}');
    final List<CalendarEvent> events = [];
    DateTime currentDate = season.startDate!;
    for (int i = 0; i < season.totalEpisodes!; i++) {
      String eventType = 'regular';
      if (i == 0) {
        eventType = 'premiere';
      } else if (i == season.totalEpisodes! - 1) {
        eventType = 'finale';
      }

      events.add(CalendarEvent(
        calendarEventId: Uuid().v4(),
        showId: season.showId!,
        seasonId: season.seasonId!,
        startDatetime: currentDate,
        endDatetime: currentDate.add(Duration(hours: 1)),
        eventType: eventType,
      ));

      switch (season.releaseFrequency) {
        case 'daily':
          currentDate = currentDate.add(Duration(days: 1));
          break;
        case 'weekly':
          currentDate = currentDate.add(Duration(days: 7));
          break;
        case 'monthly':
<<<<<<< HEAD
          currentDate = DateTime(
              currentDate.year, currentDate.month + 1, currentDate.day);
=======
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
          break;
        case 'onetime':
          break;
      }
    }

    final response = await supabaseClient
<<<<<<< HEAD
=======
        .schema('show_management')
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
        .from('calendar_events')
        .insert(events.map((e) => e.toJson()).toList());

    _logger.i('Calendar events generated successfully');
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
