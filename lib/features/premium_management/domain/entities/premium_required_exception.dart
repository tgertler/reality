class PremiumRequiredException implements Exception {
  final String feature;
  final String message;

  const PremiumRequiredException({
    required this.feature,
    required this.message,
  });

  @override
  String toString() => message;
}
