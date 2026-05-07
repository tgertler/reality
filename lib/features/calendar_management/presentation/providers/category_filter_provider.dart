import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

class GenreFiltersNotifier extends StateNotifier<Set<String>> {
  GenreFiltersNotifier() : super(const <String>{});

  void toggle(String genre) {
    final normalized = genre.trim();
    if (normalized.isEmpty) {
      return;
    }

    final next = Set<String>.from(state);
    final existing = next.firstWhere(
      (value) => value.toLowerCase() == normalized.toLowerCase(),
      orElse: () => '',
    );

    if (existing.isNotEmpty) {
      next.remove(existing);
    } else {
      next.add(normalized);
    }

    state = next;
  }

  void remove(String genre) {
    final normalized = genre.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }

    state = state
        .where((value) => value.toLowerCase() != normalized)
        .toSet();
  }

  void clear() {
    state = const <String>{};
  }
}

final selectedGenreFiltersProvider =
    StateNotifierProvider<GenreFiltersNotifier, Set<String>>(
  (ref) => GenreFiltersNotifier(),
);

final availableCalendarGenresProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  List<dynamic> response;
  String column;

  try {
    response = await supabase.from('shows').select('genre');
    column = 'genre';
  } catch (_) {
    response = await supabase.from('shows').select('kategorie');
    column = 'kategorie';
  }

  final rows = response.cast<Map<String, dynamic>>();

  final genres = <String>{};
  for (final row in rows) {
    final raw = (row[column] as String?)?.trim() ?? '';
    if (raw.isEmpty) {
      continue;
    }

    for (final chunk in raw.split(RegExp(r'[,/|]'))) {
      final value = chunk.trim();
      if (value.isNotEmpty) {
        genres.add(value);
      }
    }
  }

  final sorted = genres.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
});
