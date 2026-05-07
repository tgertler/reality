import 'package:uuid/uuid.dart';

class Show {
  final String showId;
  final String title;
  final String? shortTitle;
  final String? description;
  final String? genre;
  final String? releaseWindow;
  final String? status;
  final String? slug;
  final String? tmdbId;
  final String? traktSlug;
  final String? headerImageUrl;
  final String? mainColor;

  Show({
    required this.showId,
    required this.title,
    this.shortTitle,
    this.description,
    this.genre,
    this.releaseWindow,
    this.status,
    this.slug,
    this.tmdbId,
    this.traktSlug,
    this.headerImageUrl,
    this.mainColor,
  });

  String get displayTitle {
    final short = shortTitle?.trim();
    return (short != null && short.isNotEmpty) ? short : title;
  }

  factory Show.withRandomId({
    required String title,
    String? shortTitle,
    String? description,
    String? genre,
    String? releaseWindow,
    String? status,
    String? slug,
    String? tmdbId,
    String? traktSlug,
    String? headerImageUrl,
    String? mainColor,
  }) {
    return Show(
      showId: Uuid().v4(),
      title: title,
      shortTitle: shortTitle,
      description: description,
      genre: genre,
      releaseWindow: releaseWindow,
      status: status,
      slug: slug,
      tmdbId: tmdbId,
      traktSlug: traktSlug,
      headerImageUrl: headerImageUrl,
      mainColor: mainColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': showId,
      'title': title,
      if (shortTitle != null && shortTitle!.trim().isNotEmpty)
        'short_title': shortTitle,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
      if (genre != null && genre!.trim().isNotEmpty)
        'genre': genre,
      if (releaseWindow != null && releaseWindow!.trim().isNotEmpty)
        'release_window': releaseWindow,
      if (status != null && status!.trim().isNotEmpty)
        'status': status,
      if (slug != null && slug!.trim().isNotEmpty)
        'slug': slug,
      if (tmdbId != null && tmdbId!.trim().isNotEmpty)
        'tmdb_id': tmdbId,
      if (traktSlug != null && traktSlug!.trim().isNotEmpty)
        'trakt_slug': traktSlug,
      if (headerImageUrl != null && headerImageUrl!.trim().isNotEmpty)
        'header_image': headerImageUrl,
      if (mainColor != null && mainColor!.trim().isNotEmpty)
        'main_color': mainColor,
    };
  }
}