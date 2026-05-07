// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Show {
  final String id;
  final String? title;
  final String? shortTitle;
  final String? description;
  final String? genre;
  final String? releaseWindow;
  final String? headerImageUrl;
  final String? mainColor;

  Show({
    required this.id,
    required this.title,
    required this.description,
    this.shortTitle,
    this.genre,
    this.releaseWindow,
    this.headerImageUrl,
    this.mainColor,
  });

  String get displayTitle {
    final short = shortTitle?.trim();
    if (short != null && short.isNotEmpty) return short;
    return title ?? '';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'short_title': shortTitle,
      'description': description,
      'genre': genre,
      'release_window': releaseWindow,
      'header_image_url': headerImageUrl,
      'main_color': mainColor,
    };
  }

  factory Show.fromMap(Map<String, dynamic> map) {
    return Show(
      id: map['id'] as String,
      title: map['title'] != null ? map['title'] as String : null,
      shortTitle:
          map['short_title'] != null ? map['short_title'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
      genre: map['genre'] != null ? map['genre'] as String : null,
      releaseWindow:
          map['release_window'] != null ? map['release_window'] as String : null,
        headerImageUrl: map['header_image_url'] != null
          ? map['header_image_url'] as String
          : null,
        mainColor: map['main_color'] != null ? map['main_color'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Show.fromJson(String source) => Show.fromMap(json.decode(source) as Map<String, dynamic>);
}
