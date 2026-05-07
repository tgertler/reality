import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';

class ShowRecommendation {
  final String showId;
  final String title;
  final String subtitle;
  final String reason;
  final double score;

  const ShowRecommendation({
    required this.showId,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.score,
  });
}

final showRecommendationsProvider =
    FutureProvider.autoDispose<List<ShowRecommendation>>((ref) async {
  final userId = ref.watch(userNotifierProvider.select((state) => state.user?.id));
  final favoriteShows =
      ref.watch(favoritesNotifierProvider.select((state) => state.favoriteShows));

  if (userId == null || favoriteShows.isEmpty) {
    return const [];
  }

  final supabase = ref.read(supabaseClientProvider);
  final favoriteIds = favoriteShows.map((show) => show.showId).toSet();
  final favoriteIdList = favoriteIds.toList();

  if (favoriteIdList.isEmpty) {
    return const [];
  }

  final Map<String, double> totalScores = {};
  final Map<String, double> collaborativeScores = {};
  final Map<String, double> contentScores = {};
  final Map<String, String> bestSeedByShow = {};

  final showMetaById = await _fetchShowMetaByIds(supabase, favoriteIdList);

  final sharedRowsRaw = await supabase
      .from('user_show_relations')
      .select('user_id, show_id')
      .eq('interaction_type', 'favorite')
      .neq('user_id', userId)
      .or(_orEquals('show_id', favoriteIdList));

  final sharedRows = (sharedRowsRaw as List<dynamic>).cast<Map<String, dynamic>>();
  final Map<String, int> userAffinity = {};

  for (final row in sharedRows) {
    final similarUserId = row['user_id'] as String?;
    if (similarUserId == null || similarUserId.isEmpty) {
      continue;
    }
    userAffinity.update(similarUserId, (value) => value + 1, ifAbsent: () => 1);
  }

  if (userAffinity.isNotEmpty) {
    final similarUserIds = userAffinity.keys.toList();

    final candidateRowsRaw = await supabase
        .from('user_show_relations')
        .select('user_id, show_id')
        .eq('interaction_type', 'favorite')
        .or(_orEquals('user_id', similarUserIds));

    final candidateRows =
        (candidateRowsRaw as List<dynamic>).cast<Map<String, dynamic>>();

    for (final row in candidateRows) {
      final candidateShowId = row['show_id'] as String?;
      final candidateUserId = row['user_id'] as String?;

      if (candidateShowId == null ||
          candidateUserId == null ||
          favoriteIds.contains(candidateShowId)) {
        continue;
      }

      final affinity = (userAffinity[candidateUserId] ?? 0).toDouble();
      if (affinity <= 0) {
        continue;
      }

      final score = 1.0 + (affinity * 0.75);
      totalScores.update(candidateShowId, (value) => value + score,
          ifAbsent: () => score);
      collaborativeScores.update(candidateShowId, (value) => value + score,
          ifAbsent: () => score);
    }
  }

  final poolRowsRaw =
      await supabase.from('shows').select('id, title, short_title, description').limit(220);
  final poolRows = (poolRowsRaw as List<dynamic>).cast<Map<String, dynamic>>();

  for (final row in poolRows) {
    final id = row['id'] as String?;
    if (id == null) {
      continue;
    }
    showMetaById[id] = row;
  }

  final favoriteTokens = <String, Set<String>>{};
  for (final favoriteId in favoriteIdList) {
    final favoriteMeta = showMetaById[favoriteId];
    final title = _showTitle(favoriteMeta);
    final description = _descriptionFromMeta(favoriteMeta);
    favoriteTokens[favoriteId] = _tokenize('$title $description');
  }

  for (final row in poolRows) {
    final candidateId = row['id'] as String?;
    if (candidateId == null || favoriteIds.contains(candidateId)) {
      continue;
    }

    final candidateTokens =
        _tokenize('${_showTitle(row)} ${_descriptionFromMeta(row)}');
    if (candidateTokens.isEmpty) {
      continue;
    }

    double bestOverlap = 0;
    String? bestSeedId;

    for (final seedId in favoriteIdList) {
      final seedTokens = favoriteTokens[seedId] ?? const <String>{};
      if (seedTokens.isEmpty) {
        continue;
      }
      final overlap = _overlapScore(seedTokens, candidateTokens);
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        bestSeedId = seedId;
      }
    }

    if (bestOverlap <= 0) {
      continue;
    }

    final score = bestOverlap * 4.0;
    totalScores.update(candidateId, (value) => value + score,
        ifAbsent: () => score);
    contentScores.update(candidateId, (value) => value + score,
        ifAbsent: () => score);

    if (bestSeedId != null) {
      bestSeedByShow[candidateId] = _showTitle(showMetaById[bestSeedId]);
    }
  }

  final sorted = totalScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final recommendations = <ShowRecommendation>[];

  for (final entry in sorted) {
    if (recommendations.length >= 8) {
      break;
    }

    final showId = entry.key;
    final meta = showMetaById[showId];
    final title = _showTitle(meta);

    if (title.isEmpty) {
      continue;
    }

    final collaborative = collaborativeScores[showId] ?? 0;
    final content = contentScores[showId] ?? 0;
    final bestSeed = bestSeedByShow[showId];

    String reason;
    if (collaborative > content) {
      reason = 'Beliebt bei Nutzern mit aehnlichen Favoriten';
    } else if (bestSeed != null && bestSeed.isNotEmpty) {
      reason = 'Aehnlich zu "$bestSeed"';
    } else {
      reason = 'Passt zu deinen Favoriten';
    }

    recommendations.add(
      ShowRecommendation(
        showId: showId,
        title: title,
        subtitle: _subtitleFromMeta(meta),
        reason: reason,
        score: entry.value,
      ),
    );
  }

  return recommendations;
});

Future<Map<String, Map<String, dynamic>>> _fetchShowMetaByIds(
  dynamic supabase,
  List<String> showIds,
) async {
  if (showIds.isEmpty) {
    return {};
  }

  final rowsRaw = await supabase
      .from('shows')
      .select('id, title, short_title, description')
      .or(_orEquals('id', showIds));

  final rows = (rowsRaw as List<dynamic>).cast<Map<String, dynamic>>();
  final result = <String, Map<String, dynamic>>{};

  for (final row in rows) {
    final id = row['id'] as String?;
    if (id == null) {
      continue;
    }
    result[id] = row;
  }

  return result;
}

String _orEquals(String column, List<String> values) {
  return values.map((value) => '$column.eq.$value').join(',');
}

String _showTitle(Map<String, dynamic>? row) {
  if (row == null) {
    return '';
  }
  final shortTitle = (row['short_title'] as String?)?.trim();
  if (shortTitle != null && shortTitle.isNotEmpty) {
    return shortTitle;
  }
  return (row['title'] as String?)?.trim() ?? '';
}

String _descriptionFromMeta(Map<String, dynamic>? row) {
  return ((row?['description'] as String?) ?? '').trim();
}

String _subtitleFromMeta(Map<String, dynamic>? row) {
  final description = _descriptionFromMeta(row);
  if (description.isEmpty) {
    return 'Basierend auf deinen Favoriten';
  }
  final compact = description.replaceAll(RegExp(r'\s+'), ' ');
  if (compact.length <= 70) {
    return compact;
  }
  return '${compact.substring(0, 67)}...';
}

Set<String> _tokenize(String text) {
  if (text.trim().isEmpty) {
    return const <String>{};
  }

  final stopWords = <String>{
    'und',
    'oder',
    'der',
    'die',
    'das',
    'ein',
    'eine',
    'mit',
    'von',
    'fuer',
    'for',
    'the',
    'show',
    'serie',
    'staffel',
    'episode',
    'reality',
  };

  final normalized = text
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');

  return normalized
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.length >= 3 && !stopWords.contains(token))
      .toSet();
}

double _overlapScore(Set<String> base, Set<String> candidate) {
  if (base.isEmpty || candidate.isEmpty) {
    return 0;
  }

  final intersection = base.intersection(candidate).length.toDouble();
  if (intersection == 0) {
    return 0;
  }

  return intersection / base.length;
}
