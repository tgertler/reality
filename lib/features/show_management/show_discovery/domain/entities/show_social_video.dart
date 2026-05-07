class ShowSocialVideo {
  final String id;
  final String showId;
  final String platform;
  final String videoUrl;
  final String? embedHtml;
  final int priority;

  const ShowSocialVideo({
    required this.id,
    required this.showId,
    required this.platform,
    required this.videoUrl,
    this.embedHtml,
    required this.priority,
  });
}
