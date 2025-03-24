import '../repositories/content_repository.dart';
import '../entities/attendee.dart';

class AddAttendee {
  final ContentRepository repository;

  AddAttendee(this.repository);

  Future<void> call(Attendee attendee) async {
    await repository.addAttendee(attendee);
  }
}