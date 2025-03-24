class Season {
  final String? seasonId;
  final String? showId;
  final int? seasonNumber;
  final int? totalEpisodes;
  final String? releaseFrequency; // daily, weekly, monthly, onetime
  final DateTime? startDate;

  Season({
    required this.seasonId,
    required this.showId,
    required this.seasonNumber,
    required this.totalEpisodes,
    required this.releaseFrequency,
    required this.startDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': seasonId,
      'show_id': showId,
      'season_number': seasonNumber,
      'total_episodes': totalEpisodes,
      'release_frequency': releaseFrequency,
      'start_date': startDate?.toIso8601String(),
    };
  }
}