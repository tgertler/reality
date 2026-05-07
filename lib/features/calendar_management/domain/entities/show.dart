class Show {
  final String showId;
  final String? title;
  final String? shortTitle;
  final String? genre;

  Show({
    required this.showId,
    this.title,
    this.shortTitle,
    this.genre,
  });

  String get displayTitle {
    final short = shortTitle?.trim();
    if (short != null && short.isNotEmpty) return short;
    return title ?? '';
  }
}