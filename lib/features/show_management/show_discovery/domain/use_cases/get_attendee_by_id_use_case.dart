import 'package:frontend/features/show_management/show_discovery/domain/entities/attendee.dart';
import 'package:frontend/features/show_management/show_discovery/domain/repositories/attendee_repository.dart';
import 'package:logger/logger.dart';

import '../../../../../core/utils/logger.dart';

class GetAttendeeByIdUseCase {
  final AttendeeRepository attendeeRepository;
  final Logger _logger = getLogger('GetShowByIdUseCase');

  GetAttendeeByIdUseCase({
    required this.attendeeRepository,
  });

  Future<Attendee> execute(String id) async {
    _logger.i('Starting search with id: $id');
    try {
      final attendee = await attendeeRepository.getAttendeeById(id);
      _logger.i('Show received: $attendee');

      return attendee;
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      rethrow;
    }
  }
}