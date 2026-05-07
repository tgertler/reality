class TrashEvent {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? location;
  final String? address;
  final String? organizer;
  final String? price;
  final String? externalUrl;
  final String? relatedShowId;
  final String? relatedSeasonId;
  final DateTime createdAt;

  const TrashEvent({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.location,
    this.address,
    this.organizer,
    this.price,
    this.externalUrl,
    this.relatedShowId,
    this.relatedSeasonId,
    required this.createdAt,
  });
}
