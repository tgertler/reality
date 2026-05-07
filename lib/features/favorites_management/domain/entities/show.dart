class Show {
  final String showId;
  final String title;
  final String? shortTitle;

  Show({required this.showId, required this.title, this.shortTitle});

  String get displayTitle {
    final short = shortTitle?.trim();
    return (short != null && short.isNotEmpty) ? short : title;
  }
}