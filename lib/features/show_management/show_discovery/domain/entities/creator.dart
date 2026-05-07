class Creator {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? youtubeChannelUrl;
  final String? instagramUrl;
  final String? tiktokUrl;

  const Creator({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.youtubeChannelUrl,
    this.instagramUrl,
    this.tiktokUrl,
  });
}
