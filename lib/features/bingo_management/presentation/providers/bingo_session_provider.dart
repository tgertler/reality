import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:frontend/features/bingo_management/bingo_gateway.dart';
import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:frontend/features/premium_management/domain/entities/premium_required_exception.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';

enum BingoSessionFlowStep {
  expectation,
  prestart,
  live,
  afterglow,
  reflection,
  summary,
}

class BingoSessionState {
  final BingoSessionView? activeSession;
  final BingoSessionView? openedSession;
  final bool isOverlayOpen;
  final bool isBusy;
  final String? errorMessage;
  final BingoSessionFlowStep flowStep;
  final Map<String, String> expectationSelections;
  final int expectationCurrentIndex;
  final bool expectationSkipped;
  final String? afterglowEmoji;
  final BingoEmotionReflectionView? reflectionData;
  final BingoEpisodeRecapView? episodeRecap;
  final BingoCommunityBoardHeatmap? boardHeatmap;
  final int? liveCountdownValue;
  final BingoReactionAnchor selectedReactionAnchor;
  final BingoReactionFeedback? lastReactionFeedback;
  final BingoReactionTimelineRecap? reactionTimelineRecap;
  final BingoCrowdReactionSnapshot? crowdReactionSnapshot;

  const BingoSessionState({
    required this.activeSession,
    required this.openedSession,
    required this.isOverlayOpen,
    required this.isBusy,
    required this.errorMessage,
    required this.flowStep,
    required this.expectationSelections,
    required this.expectationCurrentIndex,
    required this.expectationSkipped,
    required this.afterglowEmoji,
    required this.reflectionData,
    required this.episodeRecap,
    required this.boardHeatmap,
    required this.liveCountdownValue,
    required this.selectedReactionAnchor,
    required this.lastReactionFeedback,
    required this.reactionTimelineRecap,
    required this.crowdReactionSnapshot,
  });

  factory BingoSessionState.initial() {
    return const BingoSessionState(
      activeSession: null,
      openedSession: null,
      isOverlayOpen: false,
      isBusy: false,
      errorMessage: null,
      flowStep: BingoSessionFlowStep.live,
      expectationSelections: <String, String>{},
      expectationCurrentIndex: 0,
      expectationSkipped: false,
      afterglowEmoji: null,
      reflectionData: null,
      episodeRecap: null,
      boardHeatmap: null,
      liveCountdownValue: null,
      selectedReactionAnchor: BingoReactionAnchor.beginning,
      lastReactionFeedback: null,
      reactionTimelineRecap: null,
      crowdReactionSnapshot: null,
    );
  }

  BingoSessionState copyWith({
    BingoSessionView? activeSession,
    BingoSessionView? openedSession,
    bool? isOverlayOpen,
    bool? isBusy,
    String? errorMessage,
    BingoSessionFlowStep? flowStep,
    Map<String, String>? expectationSelections,
    int? expectationCurrentIndex,
    bool? expectationSkipped,
    String? afterglowEmoji,
    BingoEmotionReflectionView? reflectionData,
    BingoEpisodeRecapView? episodeRecap,
    BingoCommunityBoardHeatmap? boardHeatmap,
    int? liveCountdownValue,
    BingoReactionAnchor? selectedReactionAnchor,
    BingoReactionFeedback? lastReactionFeedback,
    BingoReactionTimelineRecap? reactionTimelineRecap,
    BingoCrowdReactionSnapshot? crowdReactionSnapshot,
    bool clearError = false,
    bool clearOpenedSession = false,
    bool clearActiveSession = false,
    bool clearAfterglowEmoji = false,
    bool clearReflectionData = false,
    bool clearEpisodeRecap = false,
    bool clearBoardHeatmap = false,
    bool clearLastReactionFeedback = false,
    bool clearReactionTimelineRecap = false,
    bool clearCrowdReactionSnapshot = false,
    bool clearCountdown = false,
    bool resetExpectationState = false,
  }) {
    return BingoSessionState(
      activeSession:
          clearActiveSession ? null : (activeSession ?? this.activeSession),
      openedSession:
          clearOpenedSession ? null : (openedSession ?? this.openedSession),
      isOverlayOpen: isOverlayOpen ?? this.isOverlayOpen,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      flowStep: flowStep ?? this.flowStep,
      expectationSelections: resetExpectationState
          ? const <String, String>{}
          : (expectationSelections ?? this.expectationSelections),
      expectationCurrentIndex: resetExpectationState
          ? 0
          : (expectationCurrentIndex ?? this.expectationCurrentIndex),
      expectationSkipped: resetExpectationState
          ? false
          : (expectationSkipped ?? this.expectationSkipped),
      afterglowEmoji:
          clearAfterglowEmoji ? null : (afterglowEmoji ?? this.afterglowEmoji),
      reflectionData:
          clearReflectionData ? null : (reflectionData ?? this.reflectionData),
      episodeRecap:
          clearEpisodeRecap ? null : (episodeRecap ?? this.episodeRecap),
      boardHeatmap:
          clearBoardHeatmap ? null : (boardHeatmap ?? this.boardHeatmap),
      liveCountdownValue: clearCountdown
          ? null
          : (liveCountdownValue ?? this.liveCountdownValue),
      selectedReactionAnchor:
          selectedReactionAnchor ?? this.selectedReactionAnchor,
      lastReactionFeedback: clearLastReactionFeedback
          ? null
          : (lastReactionFeedback ?? this.lastReactionFeedback),
      reactionTimelineRecap: clearReactionTimelineRecap
          ? null
          : (reactionTimelineRecap ?? this.reactionTimelineRecap),
      crowdReactionSnapshot: clearCrowdReactionSnapshot
          ? null
          : (crowdReactionSnapshot ?? this.crowdReactionSnapshot),
    );
  }
}

class BingoSessionNotifier extends StateNotifier<BingoSessionState> {
  final BingoDatasource _datasource;
  final Ref _ref;

  BingoSessionNotifier(this._datasource, this._ref)
      : super(BingoSessionState.initial()) {
    refreshActiveSession();
  }

  Future<void> refreshActiveSession() async {
    final active = await _datasource.getActiveSession();
    state = state.copyWith(
      activeSession: active,
      clearError: true,
    );
  }

  Future<void> startSessionForShowEvent(
    String showEventId, {
    String? userId,
    bool openOverlay = true,
  }) async {
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'Du musst eingeloggt sein, um Bingo zu spielen.',
      );
      return;
    }

    try {
      final active = await _datasource.getActiveSession();
      if (active == null) {
        final history = await _datasource.getHistoryForShowEvent(showEventId);
        if (history.isNotEmpty) {
          _requirePremium(
            feature: 'bingo_replay',
            message:
                'Mehrere Bingo-Sessions pro Event sind Teil von Premium.',
          );
        }
      }
    } on PremiumRequiredException {
      rethrow;
    }

    state = state.copyWith(
      isBusy: true,
      isOverlayOpen: openOverlay,
      clearOpenedSession: openOverlay,
      clearError: true,
      clearAfterglowEmoji: true,
      clearReflectionData: true,
      clearEpisodeRecap: true,
      clearBoardHeatmap: true,
      clearLastReactionFeedback: true,
      clearReactionTimelineRecap: true,
      clearCrowdReactionSnapshot: true,
      clearCountdown: true,
      resetExpectationState: true,
      flowStep: BingoSessionFlowStep.live,
    );
    try {
      final session = await _datasource.startSessionForShowEvent(
        showEventId,
        createdBy: userId,
      );

      final expectationEntries = await _datasource.getExpectationByUser(
        sessionId: session.sessionId,
        userId: userId,
      );
      final selectionByDimension = <String, String>{
        for (final entry in expectationEntries)
          entry.dimension.toUpperCase(): entry.emoji,
      };
      final hasAllDimensions = kBingoExpectationDimensions.every(
          (dimension) => selectionByDimension.containsKey(dimension.key));

      state = state.copyWith(
        activeSession: session,
        openedSession: openOverlay ? session : state.openedSession,
        isOverlayOpen: openOverlay,
        flowStep: !openOverlay
            ? BingoSessionFlowStep.live
            : (hasAllDimensions
                ? (session.phase == BingoSessionPhase.live
                    ? BingoSessionFlowStep.live
                    : BingoSessionFlowStep.prestart)
                : BingoSessionFlowStep.expectation),
        expectationSelections: selectionByDimension,
        expectationCurrentIndex:
            _firstMissingExpectationIndex(selectionByDimension),
        expectationSkipped: false,
        isBusy: false,
      );

      if (openOverlay &&
          hasAllDimensions &&
          session.phase != BingoSessionPhase.live) {
        await _runLiveCountdown(session.sessionId);
      }
    } on PremiumRequiredException catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startSessionForLatestShowEvent(
    String showId, {
    String? userId,
    bool openOverlay = true,
  }) async {
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'Du musst eingeloggt sein, um Bingo zu spielen.',
      );
      return;
    }
    if (openOverlay) {
      state = state.copyWith(
        isOverlayOpen: true,
        clearOpenedSession: true,
        isBusy: true,
        clearError: true,
      );
    }

    final latestShowEventId =
        await _datasource.getLatestShowEventIdForShow(showId);
    if (latestShowEventId == null || latestShowEventId.isEmpty) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Keine Episode für diese Show gefunden.',
      );
      return;
    }

    await startSessionForShowEvent(
      latestShowEventId,
      userId: userId,
      openOverlay: openOverlay,
    );
  }

  Future<void> endActiveSession() async {
    final active = state.activeSession;
    if (active == null) return;

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _datasource.endSession(active.sessionId);
      state = state.copyWith(
        isBusy: false,
        clearActiveSession: true,
        clearOpenedSession: true,
        isOverlayOpen: false,
        resetExpectationState: true,
        clearAfterglowEmoji: true,
        clearReflectionData: true,
        clearEpisodeRecap: true,
        clearBoardHeatmap: true,
        clearLastReactionFeedback: true,
        clearReactionTimelineRecap: true,
        clearCrowdReactionSnapshot: true,
        clearCountdown: true,
        flowStep: BingoSessionFlowStep.live,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<BingoSessionView?> endActiveSessionKeepingOverlayOpen() async {
    final active = state.activeSession;
    if (active == null) return null;

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _datasource.endSession(active.sessionId);

      final endedSession = await _datasource.getSessionById(active.sessionId) ??
          active.copyWith(
            status: 'COMPLETED',
            endedAt: DateTime.now(),
          );

      state = state.copyWith(
        isBusy: false,
        clearActiveSession: true,
        openedSession: endedSession,
        isOverlayOpen: true,
        clearCountdown: true,
        clearCrowdReactionSnapshot: true,
        flowStep: BingoSessionFlowStep.summary,
      );

      return endedSession;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<void> selectExpectation({
    required String dimension,
    required String emoji,
    required String userId,
  }) async {
    final opened = state.openedSession;
    if (opened == null) return;

    final normalizedDimension = dimension.trim().toUpperCase();
    if (normalizedDimension.isEmpty) return;

    final nextSelections = <String, String>{
      ...state.expectationSelections,
      normalizedDimension: emoji,
    };

    final hasAllDimensions = kBingoExpectationDimensions
        .every((entry) => nextSelections.containsKey(entry.key));

    state = state.copyWith(
      expectationSelections: nextSelections,
      expectationCurrentIndex: _firstMissingExpectationIndex(nextSelections),
      flowStep: hasAllDimensions
          ? BingoSessionFlowStep.prestart
          : BingoSessionFlowStep.expectation,
      clearError: true,
    );

    try {
      await _datasource.saveExpectationSelection(
        sessionId: opened.sessionId,
        userId: userId,
        dimension: normalizedDimension,
        emoji: emoji,
      );
      if (hasAllDimensions) {
        unawaited(_runLiveCountdown(opened.sessionId));
      }
    } on PremiumRequiredException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void skipExpectationAndOpenBingo() {
    state = state.copyWith(
      expectationSkipped: true,
      flowStep: BingoSessionFlowStep.prestart,
      clearError: true,
    );
    final sessionId = state.openedSession?.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      unawaited(_runLiveCountdown(sessionId));
    }
  }

  void setReactionAnchor(BingoReactionAnchor anchor) {
    state = state.copyWith(
      selectedReactionAnchor: anchor,
      clearError: true,
    );
  }

  Future<void> sendLiveReaction({
    required String emoji,
    required String userId,
  }) async {
    final opened = state.openedSession;
    if (opened == null ||
        !opened.isActive ||
        opened.phase != BingoSessionPhase.live) {
      return;
    }

    final liveStartedAt = opened.liveStartedAt ?? opened.startedAt;
    final elapsed = DateTime.now().difference(liveStartedAt).inSeconds;
    final offset = elapsed < 0 ? 0 : elapsed;
    final anchor = state.selectedReactionAnchor;

    _requirePremium(
      feature: 'bingo_reactions',
      message: 'Live-Reaktionen sind Teil von Premium.',
    );

    try {
      await _datasource.saveLiveReaction(
        sessionId: opened.sessionId,
        showEventId: opened.showEventId,
        userId: userId,
        emoji: emoji,
        anchor: anchor,
        reactionOffsetSeconds: offset,
      );

      final feedback = await _datasource.getReactionFeedback(
        showEventId: opened.showEventId,
        selectedEmoji: emoji,
        anchor: anchor,
        reactionOffsetSeconds: offset,
      );

      state = state.copyWith(
        lastReactionFeedback: feedback,
        crowdReactionSnapshot: BingoCrowdReactionSnapshot(
          emoji: feedback.leadingEmoji,
          sampleCount: feedback.totalResponses,
          anchor: anchor,
          reactionOffsetSeconds: offset,
          createdAt: DateTime.now(),
        ),
        clearError: true,
      );
    } on PremiumRequiredException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refreshLiveCrowdReaction() async {
    final opened = state.openedSession;
    if (opened == null ||
        !opened.isActive ||
        opened.phase != BingoSessionPhase.live) {
      return;
    }

    final liveStartedAt = opened.liveStartedAt ?? opened.startedAt;
    final elapsed = DateTime.now().difference(liveStartedAt).inSeconds;
    final offset = elapsed < 0 ? 0 : elapsed;
    final anchor = state.selectedReactionAnchor;

    try {
      final snapshot = await _datasource.getCrowdReactionSnapshot(
        showEventId: opened.showEventId,
        anchor: anchor,
        reactionOffsetSeconds: offset,
      );

      state = state.copyWith(
        crowdReactionSnapshot: snapshot,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void openAfterglowStep() {
    if (state.activeSession == null) return;
    state = state.copyWith(
      flowStep: BingoSessionFlowStep.afterglow,
      clearError: true,
    );
  }

  Future<void> finishActiveSessionWithAfterglow({
    required String userId,
    required String emoji,
  }) async {
    final active = state.activeSession;
    if (active == null) return;

    state = state.copyWith(
      isBusy: true,
      flowStep: BingoSessionFlowStep.afterglow,
      clearError: true,
    );

    try {
      await _datasource.endSession(active.sessionId);
      await _datasource.saveAfterglowSelection(
        sessionId: active.sessionId,
        userId: userId,
        emoji: emoji,
      );

      final endedSession = await _datasource.getSessionById(active.sessionId) ??
          active.copyWith(
            status: 'COMPLETED',
            endedAt: DateTime.now(),
          );

      final reflection =
          await _datasource.getEmotionReflection(active.showEventId);
      final episodeRecap =
          await _datasource.getEpisodeRecap(active.showEventId);
      final boardHeatmap =
          await _datasource.getEpisodeBoardHeatmap(active.showEventId);
      final reactionTimelineRecap = await _datasource.getReactionTimelineRecap(
        sessionId: active.sessionId,
        showEventId: active.showEventId,
        userId: userId,
      );

      state = state.copyWith(
        isBusy: false,
        clearActiveSession: true,
        openedSession: endedSession,
        isOverlayOpen: true,
        flowStep: BingoSessionFlowStep.reflection,
        afterglowEmoji: emoji,
        reflectionData: reflection,
        episodeRecap: episodeRecap,
        boardHeatmap: boardHeatmap,
        reactionTimelineRecap: reactionTimelineRecap,
        clearCountdown: true,
      );
    } on PremiumRequiredException catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
    }
  }

  void openSummaryAfterReflection() {
    state = state.copyWith(
      flowStep: BingoSessionFlowStep.summary,
      clearError: true,
    );
  }

  Future<void> toggleSessionItem(
    String sessionItemId,
    bool checked, {
    String? userId,
  }) async {
    final opened = state.openedSession;
    if (opened == null || !opened.isActive) return;

    final updatedBoard = opened.boardItems
        .map((item) => item.sessionItemId == sessionItemId
            ? item.copyWith(
                checked: checked,
                checkedAt: checked ? DateTime.now() : null,
                clearCheckedAt: !checked,
              )
            : item)
        .toList();

    final updatedOpened = opened.copyWith(boardItems: updatedBoard);
    final active = state.activeSession;
    final updatedActive = active != null && active.sessionId == opened.sessionId
        ? active.copyWith(boardItems: updatedBoard)
        : active;

    state = state.copyWith(
      openedSession: updatedOpened,
      activeSession: updatedActive,
      clearError: true,
    );

    try {
      await _datasource.setSessionItemChecked(
        sessionItemId,
        checked,
        userId: userId,
      );
    } catch (e) {
      final reloaded = await _datasource.getSessionById(opened.sessionId);
      state = state.copyWith(
        openedSession: reloaded,
        activeSession:
            reloaded != null && active?.sessionId == reloaded.sessionId
                ? reloaded
                : state.activeSession,
        errorMessage: e.toString(),
      );
    }
  }

  void openActiveSessionOverlay() {
    final activeSession = state.activeSession;
    if (activeSession == null) return;
    state = state.copyWith(
      openedSession: activeSession,
      isOverlayOpen: true,
      clearError: true,
      flowStep: activeSession.phase == BingoSessionPhase.live
          ? BingoSessionFlowStep.live
          : BingoSessionFlowStep.prestart,
    );

    if (activeSession.phase != BingoSessionPhase.live) {
      unawaited(_runLiveCountdown(activeSession.sessionId));
    }
  }

  Future<void> openHistoricalSessionOverlay(String sessionId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final session = await _datasource.getSessionById(sessionId);
      if (session == null) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: 'Session konnte nicht geladen werden.',
        );
        return;
      }
      state = state.copyWith(
        openedSession: session,
        isOverlayOpen: true,
        isBusy: false,
        flowStep: BingoSessionFlowStep.summary,
        clearLastReactionFeedback: true,
        clearCrowdReactionSnapshot: true,
        clearCountdown: true,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<BingoSessionStatsView?> getSessionStats(String sessionId) {
    return _datasource.getSessionStats(sessionId);
  }

  void closeOverlay() {
    final hasActiveSession = state.activeSession != null;
    state = state.copyWith(
      isOverlayOpen: false,
      clearOpenedSession: !hasActiveSession,
      clearError: true,
      clearAfterglowEmoji: !hasActiveSession,
      clearReflectionData: !hasActiveSession,
      clearEpisodeRecap: !hasActiveSession,
      clearBoardHeatmap: !hasActiveSession,
      clearLastReactionFeedback: !hasActiveSession,
      clearReactionTimelineRecap: !hasActiveSession,
      clearCrowdReactionSnapshot: !hasActiveSession,
      clearCountdown: true,
      resetExpectationState: !hasActiveSession,
      flowStep: hasActiveSession ? state.flowStep : BingoSessionFlowStep.live,
    );
  }

  Future<void> _runLiveCountdown(String sessionId) async {
    if (state.liveCountdownValue != null) return;

    state = state.copyWith(
      flowStep: BingoSessionFlowStep.prestart,
      liveCountdownValue: 3,
      clearError: true,
    );

    for (var value = 3; value >= 1; value--) {
      state = state.copyWith(liveCountdownValue: value);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (state.openedSession?.sessionId != sessionId) return;
    }

    await _datasource.markSessionLive(sessionId);
    final refreshed = await _datasource.getSessionById(sessionId);
    final active = state.activeSession;

    state = state.copyWith(
      openedSession: refreshed ?? state.openedSession,
      activeSession: active != null && active.sessionId == sessionId
          ? (refreshed ?? active)
          : state.activeSession,
      clearCountdown: true,
      flowStep: BingoSessionFlowStep.live,
      clearError: true,
    );
  }

  int _firstMissingExpectationIndex(Map<String, String> selections) {
    for (var i = 0; i < kBingoExpectationDimensions.length; i++) {
      final key = kBingoExpectationDimensions[i].key;
      if (!selections.containsKey(key)) {
        return i;
      }
    }
    return kBingoExpectationDimensions.length - 1;
  }

  void _requirePremium({required String feature, required String message}) {
    final isPremium = _ref.read(userNotifierProvider).profile?.isPremium ?? false;
    if (isPremium) return;
    throw PremiumRequiredException(feature: feature, message: message);
  }
}

final bingoDatasourceProvider = Provider<BingoDatasource>((ref) {
  return BingoDatasource(ref.read(supabaseClientProvider));
});

final bingoSessionProvider =
    StateNotifierProvider<BingoSessionNotifier, BingoSessionState>((ref) {
  return BingoSessionNotifier(ref.read(bingoDatasourceProvider), ref);
});

final showEventBingoSummaryProvider =
    FutureProvider.family<ShowEventBingoSummary?, String>((ref, showEventId) {
  return ref.read(bingoDatasourceProvider).getShowEventSummary(showEventId);
});

final showEventBingoHistoryProvider =
    FutureProvider.family<List<BingoSessionHistoryEntry>, String>(
  (ref, showEventId) {
    // Re-fetch automatically when the active session for this event changes
    // (e.g. session ends → history gains a new entry)
    ref.watch(
      bingoSessionProvider.select(
        (s) => s.activeSession?.showEventId == showEventId,
      ),
    );
    return ref
        .read(bingoDatasourceProvider)
        .getHistoryForShowEvent(showEventId);
  },
);

final showEventIsReleasedProvider =
    FutureProvider.family<bool, String>((ref, showEventId) {
  return ref.read(bingoDatasourceProvider).isShowEventReleased(showEventId);
});

final showHasReleasedShowEventProvider =
    FutureProvider.family<bool, String>((ref, showId) async {
  final releasedId = await ref
      .read(bingoDatasourceProvider)
      .getLatestShowEventIdForShow(showId);
  return releasedId != null && releasedId.isNotEmpty;
});

final userBingoGlobalHistoryProvider =
    FutureProvider.autoDispose<List<GlobalBingoHistoryEntry>>((ref) {
  final userId =
      ref.watch(userNotifierProvider.select((s) => s.user?.id ?? ''));
  if (userId.isEmpty) return Future.value(const []);
  return ref.read(bingoDatasourceProvider).getUserBingoGlobalHistory(userId);
});

final userBingoStatsProvider =
    FutureProvider.autoDispose<UserBingoStatsView>((ref) {
  final userId =
      ref.watch(userNotifierProvider.select((s) => s.user?.id ?? ''));
  if (userId.isEmpty) return Future.value(UserBingoStatsView.empty());
  return ref.read(bingoDatasourceProvider).getUserBingoStats(userId);
});
