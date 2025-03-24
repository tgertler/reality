// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Attendee {
  final String id;
  final String? name;
  final String? bio;

  Attendee({required this.id, required this.name, required this.bio});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'bio': bio,
    };
  }

  factory Attendee.fromMap(Map<String, dynamic> map) {
    return Attendee(
      id: map['id'] as String,
      name: map['name'] != null ? map['name'] as String : null,
      bio: map['bio'] != null ? map['bio'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Attendee.fromJson(String source) => Attendee.fromMap(json.decode(source) as Map<String, dynamic>);
}
