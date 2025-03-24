class Season {
  final String id;
  final String showId;
  final int seasonNumber;
  final String? releaseFrequency;
  final int totalEpisodes;
  final String streamingOption;
  final DateTime streamingReleaseDate;

  Season(
      {required this.id,
      required this.showId,
      required this.seasonNumber,
      this.releaseFrequency,
      required this.totalEpisodes,
      required this.streamingOption,
      required this.streamingReleaseDate});
}
