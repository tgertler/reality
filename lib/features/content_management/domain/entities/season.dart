class Season {
  final String? seasonId;
  final String? showId;
  final int? seasonNumber;
  final int? totalEpisodes;
  final String? releaseFrequency; // daily, weekly, monthly, onetime
  final DateTime? startDate;
  final int? episodeLength;
  final String? streamingOption;

  Season({
    required this.seasonId,
    required this.showId,
    required this.seasonNumber,
    required this.totalEpisodes,
    required this.releaseFrequency,
    required this.startDate,
    this.episodeLength,
    this.streamingOption,
  });

  Map<String, dynamic> toJson() {
    final frequency = _normalizedFrequency(releaseFrequency);
    final releaseDays = _releaseDaysFromFrequency(releaseFrequency);
    final normalizedStreamingOption =
        _normalizedStreamingOption(streamingOption);
    final utcStart = startDate?.toUtc();

    return {
      'id': seasonId,
      'show_id': showId,
      'season_number': seasonNumber,
      'total_episodes': totalEpisodes,
      'release_frequency': frequency,
      'streaming_release_date': utcStart == null
          ? null
          : '${utcStart.year.toString().padLeft(4, '0')}-${utcStart.month.toString().padLeft(2, '0')}-${utcStart.day.toString().padLeft(2, '0')}',
      'streaming_release_time': utcStart == null
          ? null
          : '${utcStart.hour.toString().padLeft(2, '0')}:${utcStart.minute.toString().padLeft(2, '0')}:${utcStart.second.toString().padLeft(2, '0')}',
      if (episodeLength != null) 'episode_length': episodeLength,
      if (normalizedStreamingOption != null)
        'streaming_option': normalizedStreamingOption,
      if (releaseDays.isNotEmpty) 'release_days': releaseDays,
    };
  }

  String? _normalizedFrequency(String? value) {
    if (value == null) return null;
    if (value.startsWith('multi_weekly')) return 'multi_weekly';
    if (value == 'premiere3_then_weekly') return 'premiere3_weekly';
    if (value == 'premiere2_then_weekly') return 'premiere2_weekly';
    return value;
  }

  String? _normalizedStreamingOption(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= 20 ? trimmed : trimmed.substring(0, 20);
  }

  List<int> _releaseDaysFromFrequency(String? value) {
    if (value == null || !value.startsWith('multi_weekly:')) return const [];
    return value
        .split(':')
        .last
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }
}
