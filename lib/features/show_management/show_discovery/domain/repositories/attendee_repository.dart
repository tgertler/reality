import '../entities/attendee.dart';

abstract class AttendeeRepository {

  Future<List<Attendee>> search(String query);
  Future<Attendee> getAttendeeById(String id);

}