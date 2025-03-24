class Attendee {
  final String attendeeId;
  final String name;

  Attendee({required this.attendeeId, required this.name});

  Map<String, dynamic> toJson() {
    return {
      'attendee_id': attendeeId,
      'name': name,
    };
  }
}