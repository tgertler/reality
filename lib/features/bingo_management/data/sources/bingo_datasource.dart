import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BingoDatasource {
  final SupabaseClient _supabaseClient;

  const BingoDatasource(this._supabaseClient);

  Future<ShowEventBingoSummary?> getShowEventSummary(String showEventId) async {
    final row = await _supabaseClient
        .from('calendar_event_resolved')
        .select(
            'show_event_id, show_event_show_id, show_event_show_title, show_event_show_short_title, show_event_subtype, show_event_episode_number, show_event_season_number, show_event_description, start_datetime')
        .eq('is_show_event', true)
        .eq('show_event_id', showEventId)
        .order('start_datetime', ascending: true)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    return ShowEventBingoSummary(
      showEventId: row['show_event_id']?.toString() ?? showEventId,
      showId: row['show_event_show_id']?.toString() ?? '',
      showTitle: row['show_event_show_title']?.toString() ?? 'Unbekannte Show',
      showShortTitle: row['show_event_show_short_title']?.toString(),
      eventSubtype: row['show_event_subtype']?.toString(),
      episodeNumber: row['show_event_episode_number'] as int?,
      seasonNumber: row['show_event_season_number'] as int?,
      description: row['show_event_description']?.toString(),
      startDatetime: row['start_datetime'] != null
          ? DateTime.tryParse(row['start_datetime'].toString())?.toLocal()
          : null,
    );
  }

  Future<String?> getLatestShowEventIdForShow(String showId) async {
    final nowUtc = DateTime.now().toUtc();

    final latestReleased = await _supabaseClient
        .from('calendar_event_resolved')
        .select('show_event_id, start_datetime')
        .eq('is_show_event', true)
        .eq('show_event_show_id', showId)
        .lte('start_datetime', nowUtc.toIso8601String())
        .order('start_datetime', ascending: false)
        .limit(1)
        .maybeSingle();

    return latestReleased?['show_event_id']?.toString();
  }

  Future<BingoSessionView?> getActiveSession() async {
    final row = await _supabaseClient
        .from('bingo_sessions')
        .select('id')
        .eq('status', 'ACTIVE')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return getSessionById(row['id'].toString());
  }

  Future<BingoSessionView> startSessionForShowEvent(
    String showEventId, {
    String? createdBy,
  }) async {
    final active = await getActiveSession();
    if (active != null) {
      return active;
    }

    final isReleased = await _isShowEventReleased(showEventId);
    if (!isReleased) {
      throw StateError(
        'Bingo kann erst gestartet werden, wenn das Show-Event erschienen ist.',
      );
    }

    final bingoId = await _ensureBingoWithItems(showEventId);

    final sessionRow = await _supabaseClient
        .from('bingo_sessions')
        .insert({
          'bingo_id': bingoId,
          'mode': 'WATCHPARTY',
          'status': 'ACTIVE',
          if (createdBy != null && createdBy.isNotEmpty)
            'created_by': createdBy,
        })
        .select('id')
        .single();

    final sessionId = sessionRow['id']?.toString() ?? '';
    if (sessionId.isEmpty) {
      throw StateError('Bingo-Session konnte nicht erstellt werden.');
    }

    final bingoItems = await _supabaseClient
        .from('bingo_items')
        .select('id')
        .eq('bingo_id', bingoId)
        .order('position_index', ascending: true);

    final inserts = (bingoItems as List)
        .map((row) => {
              'bingo_session_id': sessionId,
              'bingo_item_id': row['id'].toString(),
            })
        .toList();

    if (inserts.isNotEmpty) {
      await _supabaseClient.from('bingo_session_items').insert(inserts);
    }

    final view = await getSessionById(sessionId);
    if (view == null) {
      throw StateError('Bingo-Session konnte nicht geladen werden.');
    }
    return view;
  }

  Future<bool> isShowEventReleased(String showEventId) {
    return _isShowEventReleased(showEventId);
  }

  Future<void> endSession(String sessionId) async {
    await _supabaseClient.from('bingo_sessions').update({
      'status': 'COMPLETED',
      'ended_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  Future<void> setSessionItemChecked(
    String sessionItemId,
    bool checked, {
    String? userId,
  }) async {
    await _supabaseClient.from('bingo_session_items').update({
      'checked_at': checked ? DateTime.now().toUtc().toIso8601String() : null,
      'checked_by': checked ? userId : null,
    }).eq('id', sessionItemId);
  }

  Future<void> saveExpectationSelection({
    required String sessionId,
    required String userId,
    required String dimension,
    required String emoji,
  }) async {
    final normalizedDimension = dimension.trim().toUpperCase();
    if (normalizedDimension.isEmpty) {
      throw ArgumentError('dimension darf nicht leer sein.');
    }

    await _supabaseClient
        .from('bingo_session_emotions')
        .delete()
        .eq('bingo_session_id', sessionId)
        .eq('user_id', userId)
        .eq('phase', BingoEmotionPhase.expectation.dbValue)
        .eq('dimension', normalizedDimension);

    await _supabaseClient.from('bingo_session_emotions').insert({
      'bingo_session_id': sessionId,
      'user_id': userId,
      'phase': BingoEmotionPhase.expectation.dbValue,
      'dimension': normalizedDimension,
      'emoji': emoji,
    });
  }

  Future<void> saveAfterglowSelection({
    required String sessionId,
    required String userId,
    required String emoji,
  }) async {
    await _supabaseClient
        .from('bingo_session_emotions')
        .delete()
        .eq('bingo_session_id', sessionId)
        .eq('user_id', userId)
        .eq('phase', BingoEmotionPhase.afterglow.dbValue)
        .eq('dimension', kAfterglowDimension);

    await _supabaseClient.from('bingo_session_emotions').insert({
      'bingo_session_id': sessionId,
      'user_id': userId,
      'phase': BingoEmotionPhase.afterglow.dbValue,
      'dimension': kAfterglowDimension,
      'emoji': emoji,
    });
  }

  Future<List<BingoSessionEmotionEntry>> getExpectationByUser({
    required String sessionId,
    required String userId,
  }) async {
    final rows = await _supabaseClient
        .from('bingo_session_emotions')
        .select('bingo_session_id, user_id, phase, dimension, emoji, created_at')
        .eq('bingo_session_id', sessionId)
        .eq('user_id', userId)
        .eq('phase', BingoEmotionPhase.expectation.dbValue);

    return (rows as List)
        .map(_asMap)
        .where((row) => row['emoji']?.toString().trim().isNotEmpty == true)
        .map(_toEmotionEntry)
        .toList();
  }

  Future<BingoEmotionReflectionView> getEmotionReflection(String showEventId) async {
    final bingoRows = await _supabaseClient
        .from('bingos')
        .select('id')
        .eq('show_event_id', showEventId);

    final bingoIds = (bingoRows as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (bingoIds.isEmpty) {
      return _emptyEmotionReflection(showEventId);
    }

    final sessionRows = await _supabaseClient
        .from('bingo_sessions')
        .select('id')
        .inFilter('bingo_id', bingoIds);

    final sessionIds = (sessionRows as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (sessionIds.isEmpty) {
      return _emptyEmotionReflection(showEventId);
    }

    final emotionRows = await _supabaseClient
        .from('bingo_session_emotions')
        .select('phase, dimension, emoji')
        .inFilter('bingo_session_id', sessionIds);

    final expectationCounts = <String, Map<String, int>>{};
    final afterglowCounts = <String, int>{};

    for (final raw in (emotionRows as List)) {
      final row = _asMap(raw);
      final phase = row['phase']?.toString().toUpperCase() ?? '';
      final dimension = row['dimension']?.toString().toUpperCase() ?? '';
      final emoji = row['emoji']?.toString() ?? '';
      if (emoji.trim().isEmpty) continue;

      if (phase == BingoEmotionPhase.expectation.dbValue) {
        final byEmoji = expectationCounts.putIfAbsent(dimension, () => {});
        byEmoji[emoji] = (byEmoji[emoji] ?? 0) + 1;
      } else if (phase == BingoEmotionPhase.afterglow.dbValue) {
        afterglowCounts[emoji] = (afterglowCounts[emoji] ?? 0) + 1;
      }
    }

    final expectationReflections = kBingoExpectationDimensions.map((dimension) {
      final counts = expectationCounts[dimension.key] ?? const <String, int>{};
      return BingoExpectationDimensionReflection(
        dimension: dimension,
        distribution: _buildDistribution(counts, dimension.options),
      );
    }).toList();

    return BingoEmotionReflectionView(
      showEventId: showEventId,
      expectationByDimension: expectationReflections,
      afterglow: BingoAfterglowReflection(
        distribution: _buildDistribution(afterglowCounts, kBingoAfterglowOptions),
      ),
    );
  }

  Future<BingoEpisodeRecapView> getEpisodeRecap(String showEventId) async {
    final bingoRows = await _supabaseClient
        .from('bingos')
        .select('id')
        .eq('show_event_id', showEventId);

    final bingoIds = (bingoRows as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (bingoIds.isEmpty) {
      return BingoEpisodeRecapView(
        showEventId: showEventId,
        totalSessions: 0,
        sessionsWithBingo: 0,
        bingoRate: 0.0,
        topMoments: const [],
        isLowDataSample: true,
      );
    }

    final sessionRows = await _supabaseClient
        .from('bingo_sessions')
        .select('id, status')
        .inFilter('bingo_id', bingoIds)
        .eq('status', 'COMPLETED');

    final sessionIds = (sessionRows as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (sessionIds.isEmpty) {
      return BingoEpisodeRecapView(
        showEventId: showEventId,
        totalSessions: 0,
        sessionsWithBingo: 0,
        bingoRate: 0.0,
        topMoments: const [],
        isLowDataSample: true,
      );
    }

    final statsRows = await _supabaseClient
        .from('bingo_session_stats')
        .select('bingo_session_id, bingo_achieved')
        .inFilter('bingo_session_id', sessionIds);

    final sessionsWithBingo = (statsRows as List)
        .map((raw) => _asMap(raw))
        .where((row) => row['bingo_achieved'] == true)
        .length;

    final bingoRate = sessionIds.isNotEmpty
        ? sessionsWithBingo / sessionIds.length
        : 0.0;

    final sessionItemsRows = await _supabaseClient
        .from('bingo_session_items')
        .select('bingo_item_id, checked_at')
        .inFilter('bingo_session_id', sessionIds)
        .not('checked_at', 'is', null);

    final clickCounts = <String, int>{};
    for (final raw in (sessionItemsRows as List)) {
      final row = _asMap(raw);
      final bingoItemId = row['bingo_item_id']?.toString();
      if (bingoItemId != null && bingoItemId.isNotEmpty) {
        clickCounts[bingoItemId] = (clickCounts[bingoItemId] ?? 0) + 1;
      }
    }

    final itemRows = await _supabaseClient
        .from('bingo_items')
        .select('id, position_index, bingo_phrases(text), bingo_event_types(key)')
        .inFilter('id', clickCounts.keys.toList())
        .order('position_index', ascending: true);

    final topMoments = <BingoCommunityTopMoment>[];
    for (final raw in (itemRows as List)) {
      final row = _asMap(raw);
      final itemId = row['id']?.toString() ?? '';
      final clickCount = clickCounts[itemId] ?? 0;
      if (itemId.isNotEmpty && clickCount > 0) {
        final phraseMap = _asMap(row['bingo_phrases']);
        final eventTypeMap = _asMap(row['bingo_event_types']);
        topMoments.add(
          BingoCommunityTopMoment(
            bingoItemId: itemId,
            phrase: phraseMap['text']?.toString() ?? 'Unbekanntes Feld',
            clickCount: clickCount,
            positionIndex: row['position_index'] as int? ?? 0,
            eventTypeKey: eventTypeMap['key']?.toString(),
          ),
        );
      }
    }

    topMoments.sort((a, b) => b.clickCount.compareTo(a.clickCount));

    final isLowDataSample = sessionIds.length < 5;

    return BingoEpisodeRecapView(
      showEventId: showEventId,
      totalSessions: sessionIds.length,
      sessionsWithBingo: sessionsWithBingo,
      bingoRate: bingoRate,
      topMoments: topMoments.take(5).toList(),
      isLowDataSample: isLowDataSample,
    );
  }

  Future<BingoCommunityBoardHeatmap> getEpisodeBoardHeatmap(
      String showEventId) async {
    final bingoRows = await _supabaseClient
        .from('bingos')
        .select('id')
        .eq('show_event_id', showEventId);

    final bingoIds = (bingoRows as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (bingoIds.isEmpty) {
      return BingoCommunityBoardHeatmap(
        showEventId: showEventId,
        totalSessions: 0,
        totalClicks: 0,
        entries: const [],
        isLowDataSample: true,
      );
    }

    final sessionRows = await _supabaseClient
        .from('bingo_sessions')
        .select('id')
        .inFilter('bingo_id', bingoIds)
        .eq('status', 'COMPLETED');

    final sessionIds = (sessionRows as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (sessionIds.isEmpty) {
      return BingoCommunityBoardHeatmap(
        showEventId: showEventId,
        totalSessions: 0,
        totalClicks: 0,
        entries: const [],
        isLowDataSample: true,
      );
    }

    final sessionItemsRows = await _supabaseClient
        .from('bingo_session_items')
        .select('bingo_item_id, checked_at')
        .inFilter('bingo_session_id', sessionIds)
        .not('checked_at', 'is', null);

    final clickCounts = <String, int>{};
    int totalClicks = 0;
    for (final raw in (sessionItemsRows as List)) {
      final row = _asMap(raw);
      final bingoItemId = row['bingo_item_id']?.toString();
      if (bingoItemId != null && bingoItemId.isNotEmpty) {
        clickCounts[bingoItemId] = (clickCounts[bingoItemId] ?? 0) + 1;
        totalClicks++;
      }
    }

    final itemRows = await _supabaseClient
        .from('bingo_items')
        .select('id, position_index, bingo_phrases(text), bingo_event_types(key)')
        .inFilter('bingo_id', bingoIds)
        .order('position_index', ascending: true);

    final entries = <BingoCommunityBoardHeatmapEntry>[];
    for (final raw in (itemRows as List)) {
      final row = _asMap(raw);
      final itemId = row['id']?.toString() ?? '';
      final clickCount = clickCounts[itemId] ?? 0;
      final phraseMap = _asMap(row['bingo_phrases']);
      final eventTypeMap = _asMap(row['bingo_event_types']);

      entries.add(
        BingoCommunityBoardHeatmapEntry(
          bingoItemId: itemId,
          phrase: phraseMap['text']?.toString() ?? 'Unbekanntes Feld',
          clickCount: clickCount,
          positionIndex: row['position_index'] as int? ?? entries.length,
          eventTypeKey: eventTypeMap['key']?.toString(),
          relativeFrequency:
              totalClicks > 0 ? clickCount / totalClicks : 0.0,
        ),
      );
    }

    final isLowDataSample = sessionIds.length < 5;

    return BingoCommunityBoardHeatmap(
      showEventId: showEventId,
      totalSessions: sessionIds.length,
      totalClicks: totalClicks,
      entries: entries,
      isLowDataSample: isLowDataSample,
    );
  }

  Future<BingoSessionView?> getSessionById(String sessionId) async {
    final sessionRow = await _supabaseClient
        .from('bingo_sessions')
        .select(
        'id, bingo_id, mode, status, started_at, ended_at, bingos!inner(show_event_id), created_by')
        .eq('id', sessionId)
        .maybeSingle();

    if (sessionRow == null) return null;

    final bingoId = sessionRow['bingo_id']?.toString() ?? '';
    final bingosMap = _asMap(sessionRow['bingos']);
    final showEventId = bingosMap['show_event_id']?.toString() ?? '';

    final summary = await getShowEventSummary(showEventId);
    final bingoItemsRows = await _supabaseClient
        .from('bingo_items')
        .select(
            'id, position_index, bingo_phrases(text), bingo_event_types(key)')
        .eq('bingo_id', bingoId)
        .order('position_index', ascending: true);

    final sessionItemsRows = await _supabaseClient
        .from('bingo_session_items')
        .select('id, bingo_item_id, checked_at')
        .eq('bingo_session_id', sessionId);

    final sessionItemByBingoItem = <String, Map<String, dynamic>>{};
    for (final raw in (sessionItemsRows as List)) {
      final row = _asMap(raw);
      final bingoItemId = row['bingo_item_id']?.toString();
      if (bingoItemId != null && bingoItemId.isNotEmpty) {
        sessionItemByBingoItem[bingoItemId] = row;
      }
    }

    final board = <BingoBoardItem>[];
    for (final raw in (bingoItemsRows as List)) {
      final row = _asMap(raw);
      final bingoItemId = row['id']?.toString() ?? '';
      final sessionItem = sessionItemByBingoItem[bingoItemId] ?? const {};

      final phraseMap = _asMap(row['bingo_phrases']);
      final eventTypeMap = _asMap(row['bingo_event_types']);
      board.add(
        BingoBoardItem(
          sessionItemId: sessionItem['id']?.toString() ?? '',
          bingoItemId: bingoItemId,
          positionIndex: row['position_index'] as int? ?? board.length,
          phrase: phraseMap['text']?.toString() ?? 'Unbekanntes Feld',
          eventTypeKey: eventTypeMap['key']?.toString(),
          checked: sessionItem['checked_at'] != null,
          checkedAt: sessionItem['checked_at'] != null
              ? DateTime.tryParse(sessionItem['checked_at'].toString())?.toLocal()
              : null,
        ),
      );
    }

    return BingoSessionView(
      sessionId: sessionId,
      bingoId: bingoId,
      showEventId: showEventId,
      showId: summary?.showId ?? '',
      showTitle: summary?.displayTitle ?? 'Unbekannte Show',
      mode: sessionRow['mode']?.toString() ?? 'WATCHPARTY',
      eventSubtype: summary?.eventSubtype,
      episodeNumber: summary?.episodeNumber,
      seasonNumber: summary?.seasonNumber,
      startedAt: DateTime.parse(sessionRow['started_at'].toString()).toLocal(),
      endedAt: sessionRow['ended_at'] != null
          ? DateTime.tryParse(sessionRow['ended_at'].toString())?.toLocal()
          : null,
      status: sessionRow['status']?.toString() ?? 'ACTIVE',
      boardItems: board,
    );
  }

  Future<BingoSessionStatsView?> getSessionStats(String sessionId) async {
    final row = await _supabaseClient
        .from('bingo_session_stats')
        .select(
            'bingo_session_id, bingo_achieved, time_to_bingo_seconds, fields_at_bingo, score, calculated_at')
        .eq('bingo_session_id', sessionId)
        .maybeSingle();

    if (row == null) return null;

    return BingoSessionStatsView(
      sessionId: row['bingo_session_id']?.toString() ?? sessionId,
      bingoAchieved: row['bingo_achieved'] == true,
      timeToBingoSeconds: _toDouble(row['time_to_bingo_seconds']),
      fieldsAtBingo: row['fields_at_bingo'] as int?,
      score: _toDouble(row['score']),
      calculatedAt: DateTime.tryParse(row['calculated_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }

  Future<List<BingoSessionHistoryEntry>> getHistoryForShowEvent(
      String showEventId) async {
    final currentUserId = _supabaseClient.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    final bingoRow = await _supabaseClient
        .from('bingos')
        .select('id')
        .eq('show_event_id', showEventId)
        .maybeSingle();

    final bingoId = bingoRow?['id']?.toString();
    if (bingoId == null || bingoId.isEmpty) return const [];

    final sessions = await _supabaseClient
        .from('bingo_sessions')
        .select('id, status, started_at, ended_at')
        .eq('bingo_id', bingoId)
        .eq('created_by', currentUserId)
        .eq('status', 'COMPLETED')
        .order('started_at', ascending: false);

    final sessionIds = (sessions as List)
        .map((raw) => _asMap(raw)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final statsBySessionId = <String, Map<String, dynamic>>{};
    if (sessionIds.isNotEmpty) {
      final statsRows = await _supabaseClient
          .from('bingo_session_stats')
          .select('bingo_session_id, bingo_achieved, time_to_bingo_seconds, fields_at_bingo')
          .inFilter('bingo_session_id', sessionIds);

      for (final raw in (statsRows as List)) {
        final row = _asMap(raw);
        final id = row['bingo_session_id']?.toString();
        if (id != null && id.isNotEmpty) {
          statsBySessionId[id] = row;
        }
      }
    }

    final history = <BingoSessionHistoryEntry>[];
    for (final raw in (sessions as List)) {
      final row = _asMap(raw);
      final sessionId = row['id']?.toString() ?? '';
      if (sessionId.isEmpty) continue;

      final view = await getSessionById(sessionId);
      if (view == null) continue;

      final statsRow = statsBySessionId[sessionId];
      final statsBingoAchieved = statsRow?['bingo_achieved'] == true;
      final bingoAchieved = statsRow == null ? view.bingoReached : statsBingoAchieved;
      final timeToBingoSeconds = _toDouble(statsRow?['time_to_bingo_seconds']);
      final fieldsAtBingo = statsRow?['fields_at_bingo'] as int?;
      final stars = _computeHistoryStars(
        bingoAchieved: bingoAchieved,
        timeToBingoSeconds: timeToBingoSeconds,
        fieldsAtBingo: fieldsAtBingo,
        checkedCount: view.checkedCount,
      );

      history.add(
        BingoSessionHistoryEntry(
          sessionId: sessionId,
          startedAt: DateTime.parse(row['started_at'].toString()).toLocal(),
          endedAt: row['ended_at'] != null
              ? DateTime.tryParse(row['ended_at'].toString())?.toLocal()
              : null,
          status: row['status']?.toString() ?? 'COMPLETED',
          checkedCount: view.checkedCount,
          totalCount: view.totalCount,
          bingoReached: bingoAchieved,
          timeToBingoSeconds: timeToBingoSeconds,
          fieldsAtBingo: fieldsAtBingo,
          stars: stars,
        ),
      );
    }

    return history;
  }

  Future<String> _ensureBingoWithItems(String showEventId) async {
    Object? lastError;

    for (final _ in const [20, 16]) {
      try {
        final rpcResult = await _supabaseClient.rpc(
          'generate_bingo_for_show_event',
          params: {
            'p_show_event_id': showEventId,
            'p_grid_size': 16,
          },
        );

        final bingoId = await _resolveBingoId(showEventId, rpcResult);
        if (bingoId.isEmpty) {
          throw StateError(
            'Bingo konnte nicht über die Datenbank-Funktion erzeugt werden.',
          );
        }

        final existingItems = await _supabaseClient
            .from('bingo_items')
            .select('id')
            .eq('bingo_id', bingoId)
            .limit(1);

        if ((existingItems as List).isEmpty) {
          throw StateError('Bingo wurde erstellt, enthält aber keine Felder.');
        }

        return bingoId;
      } on PostgrestException catch (e) {
        lastError = e;
        if (!_isRetryableBingoTypeError(e.message)) {
          rethrow;
        }
      }
    }

    throw StateError(
      lastError == null
          ? 'Bingo konnte nicht über die Datenbank-Funktion erzeugt werden.'
          : 'Bingo konnte nicht erzeugt werden: ${lastError.toString()}',
    );
  }

  Future<String> _resolveBingoId(String showEventId, dynamic rpcResult) async {
    return _extractBingoId(rpcResult) ??
        (await _supabaseClient
                .from('bingos')
                .select('id')
                .eq('show_event_id', showEventId)
                .maybeSingle())?['id']
            ?.toString() ??
        '';
  }

  bool _isRetryableBingoTypeError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('no valid bingo type left') ||
        lower.contains('no valid bingo event type left') ||
        lower.contains('valid bingo type') ||
        lower.contains('valid bingo event type');
  }

  String? _extractBingoId(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is List && value.isNotEmpty) {
      return _extractBingoId(value.first);
    }

    final map = _asMap(value);
    if (map.isEmpty) return null;

    for (final key in const [
      'bingo_id',
      'id',
      'generate_bingo_for_show_event',
    ]) {
      final raw = map[key]?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int _computeHistoryStars({
    required bool bingoAchieved,
    required double? timeToBingoSeconds,
    required int? fieldsAtBingo,
    required int checkedCount,
  }) {
    if (!bingoAchieved) return 1;

    final fields = fieldsAtBingo ?? checkedCount;
    final seconds = timeToBingoSeconds ?? 99999;

    int focusPoints;
    if (fields <= 7) {
      focusPoints = 4;
    } else if (fields <= 9) {
      focusPoints = 3;
    } else if (fields <= 12) {
      focusPoints = 2;
    } else if (fields <= 15) {
      focusPoints = 1;
    } else {
      focusPoints = 0;
    }

    int pacePoints;
    if (seconds <= 210) {
      pacePoints = 1;
    } else if (seconds <= 480) {
      pacePoints = 0;
    } else {
      pacePoints = -1;
    }

    final total = focusPoints + pacePoints;
    if (total >= 5) return 3;
    if (total >= 3) return 2;
    return 1;
  }

  BingoSessionEmotionEntry _toEmotionEntry(Map<String, dynamic> row) {
    final phaseRaw = row['phase']?.toString().toUpperCase();
    final phase = phaseRaw == BingoEmotionPhase.afterglow.dbValue
        ? BingoEmotionPhase.afterglow
        : BingoEmotionPhase.expectation;

    return BingoSessionEmotionEntry(
      sessionId: row['bingo_session_id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      phase: phase,
      dimension: row['dimension']?.toString() ?? '',
      emoji: row['emoji']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  BingoEmotionReflectionView _emptyEmotionReflection(String showEventId) {
    return BingoEmotionReflectionView(
      showEventId: showEventId,
      expectationByDimension: kBingoExpectationDimensions
          .map(
            (dimension) => BingoExpectationDimensionReflection(
              dimension: dimension,
              distribution: const [],
            ),
          )
          .toList(),
      afterglow: const BingoAfterglowReflection(distribution: []),
    );
  }

  List<BingoEmotionAggregate> _buildDistribution(
    Map<String, int> counts,
    List<BingoEmotionOption> options,
  ) {
    if (counts.isEmpty) return const [];

    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return const [];

    final optionIndexByEmoji = <String, int>{
      for (var i = 0; i < options.length; i++) options[i].emoji: i,
    };

    final entries = counts.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => BingoEmotionAggregate(
            emoji: entry.key,
            count: entry.value,
            share: entry.value / total,
          ),
        )
        .toList();

    entries.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final indexA = optionIndexByEmoji[a.emoji] ?? 999;
      final indexB = optionIndexByEmoji[b.emoji] ?? 999;
      return indexA.compareTo(indexB);
    });

    return entries;
  }

  Future<bool> _isShowEventReleased(String showEventId) async {
    final row = await _supabaseClient
        .from('calendar_event_resolved')
        .select('start_datetime')
        .eq('is_show_event', true)
        .eq('show_event_id', showEventId)
        .maybeSingle();

    final rawStart = row?['start_datetime']?.toString();
    final start = rawStart == null ? null : DateTime.tryParse(rawStart);
    if (start == null) return false;

    final startLocal = start.toLocal();
    final nowLocal = DateTime.now();

    final isSameDay = startLocal.year == nowLocal.year &&
        startLocal.month == nowLocal.month &&
        startLocal.day == nowLocal.day;

    if (isSameDay) {
      return true;
    }

    return !start.isAfter(nowLocal.toUtc());
  }
}
