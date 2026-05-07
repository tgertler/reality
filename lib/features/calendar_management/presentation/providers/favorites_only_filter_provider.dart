import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, the calendar only shows events for shows the user has favorited.
final favoritesOnlyFilterProvider = StateProvider<bool>((ref) => false);
