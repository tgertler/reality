// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Show {
  final String id;
  final String? title;
  final String? description;

  Show({required this.id, required this.title, required this.description});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
    };
  }

  factory Show.fromMap(Map<String, dynamic> map) {
    return Show(
      id: map['id'] as String,
      title: map['title'] != null ? map['title'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Show.fromJson(String source) => Show.fromMap(json.decode(source) as Map<String, dynamic>);
}
