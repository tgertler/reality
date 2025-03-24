import 'package:uuid/uuid.dart';

class Show {
  final String showId;
  final String title;

  Show({required this.showId, required this.title});

  factory Show.withRandomId({required String title}) {
    return Show(
      showId: Uuid().v4(),
      title: title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': showId,
      'title': title,
    };
  }
}