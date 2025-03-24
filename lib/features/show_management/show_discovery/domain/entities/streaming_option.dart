// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class StreamingOption {
  final int id;
  final int seasonId;
  final String platform;
  final String url;

  StreamingOption({
    required this.id,
    required this.seasonId,
    required this.platform,
    required this.url,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'seasonId': seasonId,
      'platform': platform,
      'url': url,
    };
  }

  factory StreamingOption.fromMap(Map<String, dynamic> map) {
    return StreamingOption(
      id: map['id'] as int,
      seasonId: map['seasonId'] as int,
      platform: map['platform'] as String,
      url: map['url'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory StreamingOption.fromJson(String source) => StreamingOption.fromMap(json.decode(source) as Map<String, dynamic>);
}
