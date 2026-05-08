class BingoBoardItem {
  final String sessionItemId;
  final String bingoItemId;
  final int positionIndex;
  final String phrase;
  final String? eventTypeKey;
  final bool checked;
  final DateTime? checkedAt;

  const BingoBoardItem({
    required this.sessionItemId,
    required this.bingoItemId,
    required this.positionIndex,
    required this.phrase,
    required this.eventTypeKey,
    required this.checked,
    required this.checkedAt,
  });

  BingoBoardItem copyWith({
    bool? checked,
    DateTime? checkedAt,
    bool clearCheckedAt = false,
  }) {
    return BingoBoardItem(
      sessionItemId: sessionItemId,
      bingoItemId: bingoItemId,
      positionIndex: positionIndex,
      phrase: phrase,
      eventTypeKey: eventTypeKey,
      checked: checked ?? this.checked,
      checkedAt: clearCheckedAt ? null : (checkedAt ?? this.checkedAt),
    );
  }
}

enum BingoSessionPhase {
  prestart,
  live,
  completed,
}

extension BingoSessionPhaseX on BingoSessionPhase {
  String get dbValue {
    switch (this) {
      case BingoSessionPhase.prestart:
        return 'PRESTART';
      case BingoSessionPhase.live:
        return 'LIVE';
      case BingoSessionPhase.completed:
        return 'COMPLETED';
    }
  }
}

enum BingoReactionAnchor {
  beginning,
  middle,
  end,
}

extension BingoReactionAnchorX on BingoReactionAnchor {
  String get dbValue {
    switch (this) {
      case BingoReactionAnchor.beginning:
        return 'BEGINNING';
      case BingoReactionAnchor.middle:
        return 'MIDDLE';
      case BingoReactionAnchor.end:
        return 'END';
    }
  }

  String get label {
    switch (this) {
      case BingoReactionAnchor.beginning:
        return 'Anfang';
      case BingoReactionAnchor.middle:
        return 'Mitte';
      case BingoReactionAnchor.end:
        return 'Ende';
    }
  }
}

class BingoSessionView {
  final String sessionId;
  final String bingoId;
  final String showEventId;
  final String showId;
  final String showTitle;
  final String mode;
  final String? eventSubtype;
  final int? episodeNumber;
  final int? seasonNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? countdownStartedAt;
  final DateTime? liveStartedAt;
  final BingoSessionPhase phase;
  final String status;
  final List<BingoBoardItem> boardItems;

  const BingoSessionView({
    required this.sessionId,
    required this.bingoId,
    required this.showEventId,
    required this.showId,
    required this.showTitle,
    required this.mode,
    required this.eventSubtype,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.startedAt,
    required this.endedAt,
    required this.countdownStartedAt,
    required this.liveStartedAt,
    required this.phase,
    required this.status,
    required this.boardItems,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  int get checkedCount => boardItems.where((item) => item.checked).length;

  int get totalCount => boardItems.length;

  int get gridSize {
    final total = boardItems.length;
    if (total <= 0) return 4;
    final root = total == 25 ? 5 : 4;
    return root;
  }

  bool get bingoReached {
    final size = gridSize;
    final checked = boardItems
        .where((item) => item.checked)
        .map((item) => item.positionIndex)
        .toSet();

    for (int r = 0; r < size; r++) {
      final rowComplete =
          List.generate(size, (c) => r * size + c).every(checked.contains);
      if (rowComplete) return true;
    }

    for (int c = 0; c < size; c++) {
      final colComplete =
          List.generate(size, (r) => r * size + c).every(checked.contains);
      if (colComplete) return true;
    }

    final diag1 =
        List.generate(size, (i) => i * size + i).every(checked.contains);
    if (diag1) return true;

    final diag2 = List.generate(size, (i) => i * size + (size - i - 1))
        .every(checked.contains);
    if (diag2) return true;

    return false;
  }

  BingoSessionView copyWith({
    List<BingoBoardItem>? boardItems,
    String? status,
    DateTime? endedAt,
    String? mode,
    DateTime? countdownStartedAt,
    DateTime? liveStartedAt,
    BingoSessionPhase? phase,
  }) {
    return BingoSessionView(
      sessionId: sessionId,
      bingoId: bingoId,
      showEventId: showEventId,
      showId: showId,
      showTitle: showTitle,
      mode: mode ?? this.mode,
      eventSubtype: eventSubtype,
      episodeNumber: episodeNumber,
      seasonNumber: seasonNumber,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      countdownStartedAt: countdownStartedAt ?? this.countdownStartedAt,
      liveStartedAt: liveStartedAt ?? this.liveStartedAt,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      boardItems: boardItems ?? this.boardItems,
    );
  }
}

class BingoReactionFeedback {
  final String selectedEmoji;
  final int totalResponses;
  final int sameEmojiResponses;
  final String? topOtherEmoji;
  final double sameEmojiRate;
  final DateTime createdAt;

  const BingoReactionFeedback({
    required this.selectedEmoji,
    required this.totalResponses,
    required this.sameEmojiResponses,
    required this.topOtherEmoji,
    required this.sameEmojiRate,
    required this.createdAt,
  });

  String get message {
    if (totalResponses < 3) {
      return 'Noch zu wenig los – erste kommen rein.';
    }
    if (sameEmojiRate >= 0.55) {
      return 'Die Crowd fühlt genau wie du!';
    }
    if (sameEmojiRate >= 0.35) {
      return 'Du bist damit nicht allein.';
    }
    if (topOtherEmoji == null || topOtherEmoji!.isEmpty) {
      return 'Alle reagieren gerade anders.';
    }
    return 'Die meisten reagieren mit $topOtherEmoji.';
  }

  String? get leadingEmoji {
    if (sameEmojiResponses > 0 && sameEmojiRate >= 0.5) {
      return selectedEmoji;
    }
    if (topOtherEmoji != null && topOtherEmoji!.isNotEmpty) {
      return topOtherEmoji;
    }
    if (sameEmojiResponses > 0) {
      return selectedEmoji;
    }
    return null;
  }
}

class BingoCrowdReactionSnapshot {
  final String? emoji;
  final int sampleCount;
  final BingoReactionAnchor anchor;
  final int reactionOffsetSeconds;
  final DateTime createdAt;

  const BingoCrowdReactionSnapshot({
    required this.emoji,
    required this.sampleCount,
    required this.anchor,
    required this.reactionOffsetSeconds,
    required this.createdAt,
  });

  bool get hasData => emoji != null && emoji!.isNotEmpty && sampleCount > 0;
}

class BingoReactionTimelinePoint {
  final String emoji;
  final BingoReactionAnchor anchor;
  final int offsetSeconds;
  final BingoReactionFeedback feedback;

  const BingoReactionTimelinePoint({
    required this.emoji,
    required this.anchor,
    required this.offsetSeconds,
    required this.feedback,
  });
}

class BingoReactionTimelineRecap {
  final String sessionId;
  final List<BingoReactionTimelinePoint> points;

  const BingoReactionTimelineRecap({
    required this.sessionId,
    required this.points,
  });

  bool get hasData => points.isNotEmpty;
}

class BingoSessionStatsView {
  final String sessionId;
  final bool bingoAchieved;
  final double? timeToBingoSeconds;
  final int? fieldsAtBingo;
  final double? score;
  final DateTime calculatedAt;

  const BingoSessionStatsView({
    required this.sessionId,
    required this.bingoAchieved,
    required this.timeToBingoSeconds,
    required this.fieldsAtBingo,
    required this.score,
    required this.calculatedAt,
  });
}

class BingoSessionHistoryEntry {
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final int checkedCount;
  final int totalCount;
  final bool bingoReached;
  final double? timeToBingoSeconds;
  final int? fieldsAtBingo;
  final int stars;

  const BingoSessionHistoryEntry({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.checkedCount,
    required this.totalCount,
    required this.bingoReached,
    required this.timeToBingoSeconds,
    required this.fieldsAtBingo,
    required this.stars,
  });
}

class ShowEventBingoSummary {
  final String showEventId;
  final String showId;
  final String showTitle;
  final String? showShortTitle;
  final String? eventSubtype;
  final int? episodeNumber;
  final int? seasonNumber;
  final DateTime? startDatetime;
  final String? description;

  const ShowEventBingoSummary({
    required this.showEventId,
    required this.showId,
    required this.showTitle,
    required this.showShortTitle,
    required this.eventSubtype,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.startDatetime,
    required this.description,
  });

  String get displayTitle {
    final short = showShortTitle?.trim();
    if (short != null && short.isNotEmpty) return short;
    return showTitle;
  }
}

enum BingoEmotionPhase {
  expectation,
  afterglow,
}

extension BingoEmotionPhaseX on BingoEmotionPhase {
  String get dbValue {
    switch (this) {
      case BingoEmotionPhase.expectation:
        return 'EXPECTATION';
      case BingoEmotionPhase.afterglow:
        return 'AFTERGLOW';
    }
  }
}

class BingoEmotionOption {
  final String emoji;
  final String label;

  const BingoEmotionOption({
    required this.emoji,
    required this.label,
  });
}

class BingoExpectationDimension {
  final String key;
  final String title;
  final String question;
  final List<BingoEmotionOption> options;

  const BingoExpectationDimension({
    required this.key,
    required this.title,
    required this.question,
    required this.options,
  });
}

class BingoSessionEmotionEntry {
  final String sessionId;
  final String userId;
  final BingoEmotionPhase phase;
  final String dimension;
  final String emoji;
  final DateTime createdAt;

  const BingoSessionEmotionEntry({
    required this.sessionId,
    required this.userId,
    required this.phase,
    required this.dimension,
    required this.emoji,
    required this.createdAt,
  });
}

class BingoEmotionAggregate {
  final String emoji;
  final int count;
  final double share;

  const BingoEmotionAggregate({
    required this.emoji,
    required this.count,
    required this.share,
  });
}

class BingoExpectationDimensionReflection {
  final BingoExpectationDimension dimension;
  final List<BingoEmotionAggregate> distribution;

  const BingoExpectationDimensionReflection({
    required this.dimension,
    required this.distribution,
  });

  int get totalVotes =>
      distribution.fold<int>(0, (sum, entry) => sum + entry.count);
}

class BingoAfterglowReflection {
  final List<BingoEmotionAggregate> distribution;

  const BingoAfterglowReflection({
    required this.distribution,
  });

  int get totalVotes =>
      distribution.fold<int>(0, (sum, entry) => sum + entry.count);
}

class BingoEmotionReflectionView {
  final String showEventId;
  final List<BingoExpectationDimensionReflection> expectationByDimension;
  final BingoAfterglowReflection afterglow;

  const BingoEmotionReflectionView({
    required this.showEventId,
    required this.expectationByDimension,
    required this.afterglow,
  });

  bool get hasExpectationData =>
      expectationByDimension.any((entry) => entry.totalVotes > 0);

  bool get hasAfterglowData => afterglow.totalVotes > 0;
}

class BingoJourneyPreSummary {
  final String emoji;
  final String label;
  final String escalationValue;
  final String predictabilityValue;
  final String scriptednessValue;
  final String escalationEmoji;
  final String predictabilityEmoji;
  final String scriptednessEmoji;

  const BingoJourneyPreSummary({
    required this.emoji,
    required this.label,
    required this.escalationValue,
    required this.predictabilityValue,
    required this.scriptednessValue,
    required this.escalationEmoji,
    required this.predictabilityEmoji,
    required this.scriptednessEmoji,
  });
}

BingoJourneyPreSummary? resolveBingoJourneyPreSummary(
  Map<String, String> selections,
) {
  if (selections.isEmpty) return null;

  final escalation = _dimensionSelectionInfo('ESCALATION', selections);
  final surprise = _dimensionSelectionInfo('SURPRISE', selections);
  final realness = _dimensionSelectionInfo('REALNESS', selections);
  if (escalation == null && surprise == null && realness == null) {
    return null;
  }

  final escalationIndex = escalation?.index ?? 1;
  final surpriseIndex = surprise?.index ?? 1;
  final scriptedIndex = realness == null ? 1 : (3 - realness.index);

  final chaosScore = escalationIndex + surpriseIndex;
  final dramaScore = (escalationIndex * 2) + surpriseIndex;
  final cringeScore = scriptedIndex + (escalationIndex > 1 ? 1 : 0);
  final calmScore = (3 - escalationIndex) + (3 - surpriseIndex);

  final scores = <String, int>{
    'CHAOS': chaosScore,
    'DRAMA': dramaScore,
    'CRINGE': cringeScore,
    'CALM': calmScore,
  };

  final ordered = scores.entries.toList()
    ..sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      return a.key.compareTo(b.key);
    });

  final key = ordered.first.key;
  final mapped = switch (key) {
    'CHAOS' => ('🤯', 'Chaos'),
    'DRAMA' => ('🔥', 'Drama'),
    'CRINGE' => ('😬', 'Cringe'),
    _ => ('🧊', 'Ruhige Nummer'),
  };

  return BingoJourneyPreSummary(
    emoji: mapped.$1,
    label: mapped.$2,
    escalationValue: escalation?.label ?? 'nicht gesetzt',
    predictabilityValue: surprise?.label ?? 'nicht gesetzt',
    scriptednessValue: realness?.label ?? 'nicht gesetzt',
    escalationEmoji: selections['ESCALATION'] ?? '',
    predictabilityEmoji: selections['SURPRISE'] ?? '',
    scriptednessEmoji: selections['REALNESS'] ?? '',
  );
}

List<BingoEmotionAggregate> aggregateJourneyPreCrowd(
  BingoEmotionReflectionView reflection,
) {
  final counts = <String, int>{};
  var total = 0;

  for (final section in reflection.expectationByDimension) {
    for (final entry in section.distribution) {
      final mappedEmoji = _mapExpectationEmojiToJourneyEmoji(
        dimensionKey: section.dimension.key,
        emoji: entry.emoji,
      );
      if (mappedEmoji == null) continue;
      counts[mappedEmoji] = (counts[mappedEmoji] ?? 0) + entry.count;
      total += entry.count;
    }
  }

  if (counts.isEmpty || total <= 0) return const [];

  final list = counts.entries
      .map(
        (entry) => BingoEmotionAggregate(
          emoji: entry.key,
          count: entry.value,
          share: entry.value / total,
        ),
      )
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return list;
}

String? _mapExpectationEmojiToJourneyEmoji({
  required String dimensionKey,
  required String emoji,
}) {
  if (dimensionKey == 'ESCALATION') {
    if (emoji == '🔥') return '🔥';
    if (emoji == '😬') return '🔥';
    if (emoji == '😴') return '🧊';
    return '🤯';
  }
  if (dimensionKey == 'SURPRISE') {
    if (emoji == '🤯') return '🤯';
    if (emoji == '😮') return '🔥';
    if (emoji == '🙂') return '🧊';
    return '🧊';
  }
  if (dimensionKey == 'REALNESS') {
    if (emoji == '🎭' || emoji == '😐') return '😬';
    if (emoji == '🤔') return '🔥';
    return '🧊';
  }
  return null;
}

_DimensionSelectionInfo? _dimensionSelectionInfo(
  String key,
  Map<String, String> selections,
) {
  final selectedEmoji = selections[key];
  if (selectedEmoji == null || selectedEmoji.isEmpty) return null;

  BingoExpectationDimension? dimension;
  for (final entry in kBingoExpectationDimensions) {
    if (entry.key == key) {
      dimension = entry;
      break;
    }
  }
  if (dimension == null) return null;

  for (var i = 0; i < dimension.options.length; i++) {
    final option = dimension.options[i];
    if (option.emoji == selectedEmoji) {
      return _DimensionSelectionInfo(index: i, label: option.label);
    }
  }
  return null;
}

class _DimensionSelectionInfo {
  final int index;
  final String label;

  const _DimensionSelectionInfo({
    required this.index,
    required this.label,
  });
}

// ─── Community Episode Recap ──────────────────────────────────────────

class BingoCommunityTopMoment {
  final String bingoItemId;
  final String phrase;
  final int clickCount;
  final int positionIndex;
  final String? eventTypeKey;

  const BingoCommunityTopMoment({
    required this.bingoItemId,
    required this.phrase,
    required this.clickCount,
    required this.positionIndex,
    required this.eventTypeKey,
  });
}

class BingoEpisodeRecapView {
  final String showEventId;
  final int totalSessions;
  final int sessionsWithBingo;
  final double bingoRate;
  final List<BingoCommunityTopMoment> topMoments;
  final bool isLowDataSample;

  const BingoEpisodeRecapView({
    required this.showEventId,
    required this.totalSessions,
    required this.sessionsWithBingo,
    required this.bingoRate,
    required this.topMoments,
    required this.isLowDataSample,
  });

  bool get hasData => totalSessions > 0;
}

class BingoCommunityBoardHeatmapEntry {
  final String bingoItemId;
  final String phrase;
  final int clickCount;
  final int positionIndex;
  final String? eventTypeKey;
  final double relativeFrequency;

  const BingoCommunityBoardHeatmapEntry({
    required this.bingoItemId,
    required this.phrase,
    required this.clickCount,
    required this.positionIndex,
    required this.eventTypeKey,
    required this.relativeFrequency,
  });
}

class BingoCommunityBoardHeatmap {
  final String showEventId;
  final int totalSessions;
  final int totalClicks;
  final List<BingoCommunityBoardHeatmapEntry> entries;
  final bool isLowDataSample;

  const BingoCommunityBoardHeatmap({
    required this.showEventId,
    required this.totalSessions,
    required this.totalClicks,
    required this.entries,
    required this.isLowDataSample,
  });

  bool get hasData => totalSessions > 0 && entries.isNotEmpty;
}

const List<BingoExpectationDimension> kBingoExpectationDimensions = [
  BingoExpectationDimension(
    key: 'ESCALATION',
    title: 'Eskalation',
    question: 'Wie stark eskaliert es heute?',
    options: [
      BingoEmotionOption(emoji: '😴', label: 'Ruhig'),
      BingoEmotionOption(emoji: '🙂', label: 'Leichtes Drama'),
      BingoEmotionOption(emoji: '😬', label: 'Spannung'),
      BingoEmotionOption(emoji: '🔥', label: 'Eskaliert komplett'),
    ],
  ),
  BingoExpectationDimension(
    key: 'SURPRISE',
    title: 'Überraschung',
    question: 'Wie vorhersehbar wird die Folge?',
    options: [
      BingoEmotionOption(emoji: '🙄', label: 'Schon gesehen'),
      BingoEmotionOption(emoji: '🙂', label: 'Teilweise'),
      BingoEmotionOption(emoji: '😮', label: 'Überraschend'),
      BingoEmotionOption(emoji: '🤯', label: 'Komplett wild'),
    ],
  ),
  BingoExpectationDimension(
    key: 'REALNESS',
    title: 'Realness',
    question: 'Wie "scripted" wird es sein?',
    options: [
      BingoEmotionOption(emoji: '🎭', label: 'Komplett gespielt'),
      BingoEmotionOption(emoji: '😐', label: 'Erwartbar'),
      BingoEmotionOption(emoji: '🤔', label: 'Kann schon sein'),
      BingoEmotionOption(emoji: '😳', label: 'Fast glaubwürdig'),
    ],
  ),
];

const String kAfterglowDimension = 'AFTERGLOW';

const List<BingoEmotionOption> kBingoAfterglowOptions = [
  BingoEmotionOption(emoji: '🔥', label: 'Eskalation'),
  BingoEmotionOption(emoji: '😬', label: 'Cringe'),
  BingoEmotionOption(emoji: '😢', label: 'Emotion'),
  BingoEmotionOption(emoji: '🤯', label: 'Chaos'),
  BingoEmotionOption(emoji: '🙄', label: 'Nichts\nNeues'),
  BingoEmotionOption(emoji: '🧊', label: 'Ruhig'),
];

// ─────────────────────────────────────────────────────────────────────────────
// User-level bingo statistics (premium feature: Persönliche Statistiken)
// ─────────────────────────────────────────────────────────────────────────────

class UserBingoStatsTopShow {
  final String showTitle;
  final int sessionCount;
  final int bingoCount;

  const UserBingoStatsTopShow({
    required this.showTitle,
    required this.sessionCount,
    required this.bingoCount,
  });

  factory UserBingoStatsTopShow.fromJson(Map<String, dynamic> json) {
    return UserBingoStatsTopShow(
      showTitle: json['show_title']?.toString() ?? '',
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      bingoCount: (json['bingo_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserBingoStatsView {
  final int totalSessions;
  final int totalBingos;
  final double bingoRate;
  final double? bestTimeSeconds;
  final double avgScore;
  final double avgFieldsAtBingo;
  final double topScore;
  final List<UserBingoStatsTopShow> topShows;

  const UserBingoStatsView({
    required this.totalSessions,
    required this.totalBingos,
    required this.bingoRate,
    required this.bestTimeSeconds,
    required this.avgScore,
    required this.avgFieldsAtBingo,
    required this.topScore,
    required this.topShows,
  });

  factory UserBingoStatsView.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final rawShows = json['top_shows'];
    final topShows = (rawShows is List)
        ? rawShows
            .whereType<Map>()
            .map((e) => UserBingoStatsTopShow.fromJson(
                Map<String, dynamic>.from(e)))
            .toList()
        : <UserBingoStatsTopShow>[];

    return UserBingoStatsView(
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      totalBingos: (json['total_bingos'] as num?)?.toInt() ?? 0,
      bingoRate: _d(json['bingo_rate']) ?? 0.0,
      bestTimeSeconds: _d(json['best_time_seconds']),
      avgScore: _d(json['avg_score']) ?? 0.0,
      avgFieldsAtBingo: _d(json['avg_fields_at_bingo']) ?? 0.0,
      topScore: _d(json['top_score']) ?? 0.0,
      topShows: topShows,
    );
  }

  static UserBingoStatsView empty() {
    return const UserBingoStatsView(
      totalSessions: 0,
      totalBingos: 0,
      bingoRate: 0,
      bestTimeSeconds: null,
      avgScore: 0,
      avgFieldsAtBingo: 0,
      topScore: 0,
      topShows: [],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global bingo history entry (premium feature: Session-Historie)
// ─────────────────────────────────────────────────────────────────────────────

class GlobalBingoHistoryEntry {
  final String sessionId;
  final String showTitle;
  final int? episodeNumber;
  final int? seasonNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool bingoReached;
  final double? timeToBingoSeconds;
  final int? fieldsAtBingo;
  final double? score;
  final int stars;

  const GlobalBingoHistoryEntry({
    required this.sessionId,
    required this.showTitle,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.startedAt,
    required this.endedAt,
    required this.bingoReached,
    required this.timeToBingoSeconds,
    required this.fieldsAtBingo,
    required this.score,
    required this.stars,
  });
}
