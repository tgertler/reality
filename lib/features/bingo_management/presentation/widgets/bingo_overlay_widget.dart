import 'dart:math' show sqrt;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/bingo_management/presentation/widgets/bingo_help_button.dart';
import 'package:frontend/features/bingo_management/presentation/widgets/bingo_run_summary_sheet.dart';
import 'package:frontend/features/premium_management/presentation/providers/premium_waitlist_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class BingoOverlayWidget extends ConsumerStatefulWidget {
  const BingoOverlayWidget({super.key});

  @override
  ConsumerState<BingoOverlayWidget> createState() => _BingoOverlayWidgetState();
}

class _BingoOverlayWidgetState extends ConsumerState<BingoOverlayWidget> {
  static const Duration _celebrationVisibleDuration =
      Duration(milliseconds: 2800);
  double _dragDy = 0;
  String? _lastObservedSessionId;
  bool _lastObservedBingoReached = false;
  final Set<String> _celebrationShownForSession = <String>{};
  bool _isRunSummaryOpen = false;
  bool _isCelebratingBingo = false;
  int _celebrationGeneration = 0;
  bool _showInlineSummary = false;
  String? _inlineSummarySessionId;
  BingoRunSummaryData? _inlineSummaryData;
  String? _tappedExpectationEmoji;
  String? _tappedAfterglowEmoji;
  final PageController _reflectionPageController = PageController();
  String? _recapDeckSessionId;
  int _recapDeckIndex = 0;
  final List<GlobalKey> _recapCardKeys =
      List<GlobalKey>.generate(8, (_) => GlobalKey());
  final GlobalKey _userBoardShareKey = GlobalKey();

  @override
  void dispose() {
    _reflectionPageController.dispose();
    super.dispose();
  }

  bool _isQuoteItem(String phrase, String? eventTypeKey) {
    final normalizedKey = eventTypeKey?.trim().toLowerCase() ?? '';
    if (normalizedKey.contains('quote') || normalizedKey.contains('zitat')) {
      return true;
    }
    return _hasQuoteBoundaries(phrase);
  }

  bool _hasQuoteBoundaries(String phrase) {
    final trimmed = phrase.trim();
    if (trimmed.length < 2) return false;
    const openingQuotes = ['"', '„', '“', '«', '‹'];
    const closingQuotes = ['"', '“', '”', '»', '›'];
    return openingQuotes.any(trimmed.startsWith) &&
        closingQuotes.any(trimmed.endsWith);
  }

  String _displayPhrase(String phrase, String? eventTypeKey) {
    final trimmed = phrase.trim();
    if (!_isQuoteItem(trimmed, eventTypeKey) || _hasQuoteBoundaries(trimmed)) {
      return _formatForGermanWrap(trimmed);
    }
    return _formatForGermanWrap('„$trimmed“');
  }

  String _formatForGermanWrap(String text) {
    // Keep the phrases free of hidden soft-hyphen characters because iOS may
    // interpret them as spelling/grammar issues and draw yellow markings.
    return text
        .replaceAll('/', '/\u200B')
        .replaceAll('-', '-\u200B')
        .replaceAll('·', '·\u200B');
  }

  double _adaptiveGridFontSize(String phrase, int gridSize) {
    final len = phrase.trim().length;
    final words =
        phrase.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    var longestWord = 0;
    for (final w in words) {
      if (w.length > longestWord) longestWord = w.length;
    }

    var score = len + (longestWord * 0.9);
    if (gridSize >= 5) score += 8;
    if (gridSize <= 3) score -= 4;

    if (score <= 26) return 16;
    if (score <= 34) return 15;
    if (score <= 44) return 14;
    if (score <= 56) return 13.5;
    if (score <= 68) return 13;
    if (score <= 82) return 12.5;
    if (score <= 98) return 12;
    return 11.5;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = _dragDy + details.delta.dy;
    setState(() {
      _dragDy = next < 0 ? 0 : next;
    });
  }

  void _handleDragEnd(DragEndDetails details, VoidCallback closeOverlay) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDy > 140 || velocity > 900) {
      closeOverlay();
      setState(() => _dragDy = 0);
      return;
    }
    setState(() => _dragDy = 0);
  }

  void _scheduleRunSummaryCheck(
    BingoSessionView session,
    bool isActiveSessionOpen,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isRunSummaryOpen) return;

      final sessionId = session.sessionId;
      final reachedNow = session.bingoReached;

      if (_lastObservedSessionId != sessionId) {
        _lastObservedSessionId = sessionId;
        _lastObservedBingoReached = reachedNow;

        if (_inlineSummarySessionId != sessionId && _showInlineSummary) {
          setState(() {
            _showInlineSummary = false;
            _inlineSummarySessionId = null;
            _inlineSummaryData = null;
          });
        }

        if (isActiveSessionOpen && reachedNow) {
          _maybeCelebrateFirstBingo(session);
        }
        return;
      }

      final justReachedBingo = !_lastObservedBingoReached && reachedNow;
      _lastObservedBingoReached = reachedNow;

      if (isActiveSessionOpen && justReachedBingo) {
        _maybeCelebrateFirstBingo(session);
      }
    });
  }

  Future<void> _maybeCelebrateFirstBingo(BingoSessionView session) async {
    if (_celebrationShownForSession.contains(session.sessionId)) return;
    _celebrationShownForSession.add(session.sessionId);
    await _showInlineBingoCelebration();
  }

  Future<void> _presentRunSummary(
    BingoSessionView session, {
    bool showImmediately = true,
  }) async {
    if (_isRunSummaryOpen || !mounted) return;

    _isRunSummaryOpen = true;
    try {
      final stats = await ref
          .read(bingoSessionProvider.notifier)
          .getSessionStats(session.sessionId);
      if (!mounted) return;

      final summaryData = BingoRunSummaryData.fromSession(
        session: session,
        stats: stats,
      );

      setState(() {
        _inlineSummaryData = summaryData;
        _inlineSummarySessionId = session.sessionId;
        if (showImmediately) {
          _showInlineSummary = true;
        }
      });
    } finally {
      _isRunSummaryOpen = false;
    }
  }

  Future<void> _playAgain(BingoSessionView session) async {
    final notifier = ref.read(bingoSessionProvider.notifier);
    final currentState = ref.read(bingoSessionProvider);
    final userId = ref.read(userNotifierProvider).user?.id;

    setState(() {
      _showInlineSummary = false;
      _inlineSummaryData = null;
      _inlineSummarySessionId = null;
    });

    if (currentState.activeSession?.sessionId == session.sessionId) {
      await notifier.endActiveSession();
    }

    await notifier.startSessionForShowEvent(
      session.showEventId,
      userId: userId,
      openOverlay: true,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Neue Bingo-Session gestartet'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showInlineBingoCelebration() async {
    if (!mounted) return;
    final generation = ++_celebrationGeneration;
    setState(() => _isCelebratingBingo = true);
    await Future<void>.delayed(_celebrationVisibleDuration);
    if (!mounted || generation != _celebrationGeneration) return;
    setState(() => _isCelebratingBingo = false);
  }

  void _ensureRecapDeckFocusForSession(String sessionId) {
    if (_recapDeckSessionId == sessionId) {
      return;
    }

    _recapDeckSessionId = sessionId;
    _recapDeckIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_reflectionPageController.hasClients) return;
      _reflectionPageController.jumpToPage(0);
    });
  }

  void _clearLocalOverlayState() {
    _showInlineSummary = false;
    _inlineSummarySessionId = null;
    _inlineSummaryData = null;
    _tappedExpectationEmoji = null;
    _tappedAfterglowEmoji = null;
    _isCelebratingBingo = false;
    _recapDeckSessionId = null;
    _recapDeckIndex = 0;
  }

  Future<void> _shareRecapCardAsImage({
    required int cardIndex,
    required String cardLabel,
  }) async {
    if (cardIndex < 0 || cardIndex >= _recapCardKeys.length) return;

    final key = _recapCardKeys[cardIndex];
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karte konnte gerade nicht geteilt werden.')),
      );
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'bingo_${cardLabel.toLowerCase()}.png',
          ),
        ],
        text: 'Meine Bingo Session Story: $cardLabel',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teilen fehlgeschlagen. Bitte erneut probieren.')),
      );
    }
  }

  Future<void> _shareUserBingoBoard() async {
    final boundary = _userBoardShareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bingo-Board konnte gerade nicht geteilt werden.')),
      );
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'mein_watchparty_bingo_board.png',
          ),
        ],
        text: 'Mein komplettes Watchparty-Bingo 🎰🍷',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teilen fehlgeschlagen. Bitte erneut probieren.')),
      );
    }
  }


  void _syncLocalOverlayState({
    required bool isOverlayOpen,
    String? sessionId,
  }) {
    final shouldClearForClosedOverlay =
        !isOverlayOpen &&
        (_showInlineSummary ||
            _inlineSummarySessionId != null ||
            _inlineSummaryData != null ||
            _tappedExpectationEmoji != null ||
            _tappedAfterglowEmoji != null ||
            _isCelebratingBingo);
    final shouldClearForDifferentSession =
        sessionId != null &&
        _inlineSummarySessionId != null &&
        _inlineSummarySessionId != sessionId;

    if (!shouldClearForClosedOverlay && !shouldClearForDifferentSession) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(_clearLocalOverlayState);
    });
  }

  Widget _buildMainContent({
    required BingoSessionState state,
    required BingoSessionView session,
    required bool isActiveSessionOpen,
  }) {
    if (_showInlineSummary && _inlineSummaryData != null) {
      return Padding(
        key: const ValueKey('run_summary_inline'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: BingoRunSummarySheet(
          embedded: true,
          data: _inlineSummaryData!,
          onPlayAgain: () async {
            await _playAgain(session);
          },
          onViewRuns: () {
            ref.read(bingoSessionProvider.notifier).closeOverlay();
          },
          onViewRanking: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ranking folgt in einem spaeteren Update.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }

    switch (state.flowStep) {
      case BingoSessionFlowStep.expectation:
        return _buildExpectationStep(state, session, isActiveSessionOpen);
      case BingoSessionFlowStep.afterglow:
        return _buildAfterglowStep(isActiveSessionOpen);
      case BingoSessionFlowStep.reflection:
        return _buildReflectionStep(state, session);
      case BingoSessionFlowStep.summary:
        if (_inlineSummaryData != null) {
          return Padding(
            key: const ValueKey('run_summary_only'),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: BingoRunSummarySheet(
              embedded: true,
              data: _inlineSummaryData!,
              onPlayAgain: () async {
                await _playAgain(session);
              },
              onViewRuns: () {
                ref.read(bingoSessionProvider.notifier).closeOverlay();
              },
              onViewRanking: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ranking folgt in einem spaeteren Update.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          );
        }
        return _buildBoard(session, isActiveSessionOpen);
      case BingoSessionFlowStep.live:
        return _buildBoard(session, isActiveSessionOpen);
    }
  }

  Widget _buildBoard(BingoSessionView session, bool isActiveSessionOpen) {
    return Padding(
      key: const ValueKey('run_board'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GridView.builder(
        primary: false,
        padding: const EdgeInsets.only(top: 18),
        itemCount: session.boardItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: session.gridSize,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final item = session.boardItems[index];
          final canTap = isActiveSessionOpen;
          final isQuoteItem = _isQuoteItem(
            item.phrase,
            item.eventTypeKey,
          );
            final cellBgColor = item.checked
              ? const ui.Color.fromARGB(159, 46, 74, 77)
              : const Color(0xFF171717);
            final cellTextColor = Colors.white;
            final cellBorderColor = item.checked
              ? const Color(0xFF7FAEB0)
              : const Color(0xFF2B2B2B);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (!canTap || item.checked)
                  ? null
                  : () {
                      final userId = ref.read(userNotifierProvider).user?.id;
                      ref.read(bingoSessionProvider.notifier).toggleSessionItem(
                            item.sessionItemId,
                            true,
                            userId: userId,
                          );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cellBgColor,
                  border: Border.all(
                    color: cellBorderColor,
                    width: item.checked ? 2.1 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: item.checked ? 0.55 : 0.35),
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _AutoScrollingPhraseText(
                            text: _displayPhrase(
                              item.phrase,
                              item.eventTypeKey,
                            ),
                            style: GoogleFonts.dmSans(
                              color: cellTextColor,
                              fontSize: _adaptiveGridFontSize(
                                item.phrase,
                                session.gridSize,
                              ),
                              height: 1.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isQuoteItem) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Zitat',
                              style: GoogleFonts.montserrat(
                                color: item.checked
                                  ? Colors.white70
                                  : Colors.white54,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          item.checked
                              ? Transform.rotate(
                                  angle: -0.06,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      border: Border.fromBorderSide(
                                        BorderSide(
                                          color: Colors.black,
                                          width: 1.5,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                )
                              : Transform.rotate(
                                  angle: -0.02,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF131313),
                                      border: Border.fromBorderSide(
                                        BorderSide(
                                          color: Color(0xFF6A6A6A),
                                          width: 1.5,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    // child: const Icon(
                                    //   Icons.radio_button_unchecked_rounded,
                                    //   size: 12,
                                    //   color: Color(0xFF6A6A6A),
                                    // ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpectationStep(
    BingoSessionState state,
    BingoSessionView session,
    bool isActiveSessionOpen,
  ) {
    final userId = ref.read(userNotifierProvider).user?.id;
    if (!isActiveSessionOpen || userId == null) {
      return _buildBoard(session, false);
    }

    final index = state.expectationCurrentIndex
        .clamp(0, kBingoExpectationDimensions.length - 1);
    final dimension = kBingoExpectationDimensions[index];

    return Padding(
      key: ValueKey('expectation_$index'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: -0.02,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 1.8),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                ],
              ),
              child: Text(
                'CHECK-IN',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dimension.question,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tipp dein Bauchgefühl vor dem Start.',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            //color: const Color(0xFF141414),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   dimension.title,
                //   style: GoogleFonts.montserrat(
                //     color: AppColors.pop,
                //     fontSize: 12,
                //     fontWeight: FontWeight.w700,
                //     letterSpacing: 0.8,
                //   ),
                // ),
                const SizedBox(height: 4),
                ...dimension.options.map(
                  (option) {
                    final isTapped = _tappedExpectationEmoji == option.emoji;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: isTapped
                              ? AppColors.secondary.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: isTapped
                                ? AppColors.secondary.withValues(alpha: 0.8)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(
                                () => _tappedExpectationEmoji = option.emoji);
                            ref
                                .read(bingoSessionProvider.notifier)
                                .selectExpectation(
                                  dimension: dimension.key,
                                  emoji: option.emoji,
                                  userId: userId,
                                );
                            Future<void>.delayed(
                                const Duration(milliseconds: 250), () {
                              if (mounted) {
                                setState(() => _tappedExpectationEmoji = null);
                              }
                            });
                          },
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Text(
                                        option.emoji,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                    const WidgetSpan(
                                        child: SizedBox(width: 12)),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Text(
                                        option.label,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ref
                    .read(bingoSessionProvider.notifier)
                    .skipExpectationAndOpenBingo();
              },
              child: Text(
                'Überspringen - Zum Bingo',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfterglowStep(bool isActiveSessionOpen) {
    final userId = ref.read(userNotifierProvider).user?.id;
    if (!isActiveSessionOpen || userId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      key: const ValueKey('afterglow_step'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: -0.02,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 1.8),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                ],
              ),
              child: Text(
                'CHECK-OUT',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Was bleibt heute hängen?',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wie fühlst du dich direkt nach der Folge?',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              shrinkWrap: false,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: kBingoAfterglowOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                final option = kBingoAfterglowOptions[index];
                final isTapped = _tappedAfterglowEmoji == option.emoji;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isTapped
                        ? AppColors.secondary.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                      color: isTapped
                          ? AppColors.secondary.withValues(alpha: 0.8)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.heavyImpact();
                      setState(() => _tappedAfterglowEmoji = option.emoji);
                      await ref
                          .read(bingoSessionProvider.notifier)
                          .finishActiveSessionWithAfterglow(
                            userId: userId,
                            emoji: option.emoji,
                          );
                      final opened =
                          ref.read(bingoSessionProvider).openedSession;
                      if (opened != null) {
                        await _presentRunSummary(opened,
                            showImmediately: false);
                      }
                      if (mounted) setState(() => _tappedAfterglowEmoji = null);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Text(
                                  option.emoji,
                                  style: const TextStyle(fontSize: 50),
                                ),
                              ),
                              const WidgetSpan(child: SizedBox(width: 12)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Text(
                                  option.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionStep(
      BingoSessionState state, BingoSessionView session) {
    final reflection = state.reflectionData;
    if (reflection == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _ensureRecapDeckFocusForSession(session.sessionId);

    final journeyPre = resolveBingoJourneyPreSummary(state.expectationSelections);
    final userAfterglowEmoji = state.afterglowEmoji;
    final expectationByDimension = reflection.expectationByDimension;
    final afterglowCrowd = reflection.afterglow.distribution;
    final recapTitle = _buildRecapDeckTitle(session);
    final hasExpectationAnswers = state.expectationSelections.isNotEmpty;
    final hasAfterglowAnswer = userAfterglowEmoji != null && userAfterglowEmoji.isNotEmpty;

    final recapPages = <Widget>[];

    void addRecapPage({
      required Widget child,
      required String cardLabel,
    }) {
      final pageIndex = recapPages.length;
      recapPages.add(
        RepaintBoundary(
          key: _recapCardKeys[pageIndex],
          child: child,
        ),
      );
    }

    if (hasExpectationAnswers && hasAfterglowAnswer) {
      addRecapPage(
        cardLabel: 'my_journey',
        child: _MyJourneyCard(
          deckTitle: recapTitle,
          journeyPre: journeyPre,
          afterglowEmoji: userAfterglowEmoji,
          onShare: () => _shareRecapCardAsImage(
            cardIndex: 0,
            cardLabel: 'my_journey',
          ),
        ),
      );
    }

    if (hasExpectationAnswers) {
      final pageIndex = recapPages.length;
      addRecapPage(
        cardLabel: 'pre_vs_crowd',
        child: _PreVsCrowdCard(
          deckTitle: recapTitle,
          expectationByDimension: expectationByDimension,
          userSelections: state.expectationSelections,
          onShare: () => _shareRecapCardAsImage(
            cardIndex: pageIndex,
            cardLabel: 'pre_vs_crowd',
          ),
        ),
      );
    }

    if (hasAfterglowAnswer) {
      final pageIndex = recapPages.length;
      addRecapPage(
        cardLabel: 'post_vs_crowd',
        child: _PostVsCrowdCard(
          deckTitle: recapTitle,
          afterglowEntries: afterglowCrowd,
          afterglowEmoji: userAfterglowEmoji,
          onShare: () => _shareRecapCardAsImage(
            cardIndex: pageIndex,
            cardLabel: 'post_vs_crowd',
          ),
        ),
      );
    }

    final runSummaryPageIndex = recapPages.length;
    addRecapPage(
      cardLabel: 'run',
      child: _RunSummaryDeckCard(
        deckTitle: recapTitle,
        summaryData: _inlineSummaryData,
        checkedItems: session.boardItems.where((i) => i.checked).toList(),
        onShare: () => _shareRecapCardAsImage(
          cardIndex: runSummaryPageIndex,
          cardLabel: 'run',
        ),
        onShareBoard: _shareUserBingoBoard,
        onPlayAgain: () => _playAgain(session),
        onViewRuns: () {
          ref.read(bingoSessionProvider.notifier).closeOverlay();
        },
        onViewRanking: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ranking folgt in einem spaeteren Update.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );

    final episodeRecapPageIndex = recapPages.length;
    addRecapPage(
      cardLabel: 'episode_recap',
      child: _EpisodeRecapCard(
        deckTitle: recapTitle,
        recapData: state.episodeRecap,
        onShare: () => _shareRecapCardAsImage(
          cardIndex: episodeRecapPageIndex,
          cardLabel: 'episode_recap',
        ),
      ),
    );

    final boardHeatmapPageIndex = recapPages.length;
    addRecapPage(
      cardLabel: 'board_heatmap',
      child: _CommunityBoardHeatmapCard(
        deckTitle: recapTitle,
        heatmapData: state.boardHeatmap,
        onShare: () => _shareRecapCardAsImage(
          cardIndex: boardHeatmapPageIndex,
          cardLabel: 'board_heatmap',
        ),
      ),
    );

    if (_recapDeckIndex >= recapPages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reflectionPageController.hasClients) return;
        _reflectionPageController.jumpToPage(recapPages.length - 1);
        setState(() {
          _recapDeckIndex = recapPages.length - 1;
        });
      });
    }

    return Padding(
      key: const ValueKey('reflection_step'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecapDeckDots(index: _recapDeckIndex, count: recapPages.length),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _reflectionPageController,
                  onPageChanged: (index) {
                    if (_recapDeckIndex == index) return;
                    setState(() {
                      _recapDeckIndex = index;
                    });
                  },
                  children: recapPages,
                ),
              ),
            ],
          ),
          Offstage(
            child: RepaintBoundary(
              key: _userBoardShareKey,
              child: _UserBingoBoardShareWidget(session: session),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bingoSessionProvider);
    final session = state.openedSession;

    _syncLocalOverlayState(
      isOverlayOpen: state.isOverlayOpen,
      sessionId: session?.sessionId,
    );

    if (!state.isOverlayOpen) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(bingoSessionProvider.notifier);

    if (session == null) {
      return Positioned.fill(
        child: Stack(
          children: [
            GestureDetector(
              onTap: notifier.closeOverlay,
              child: Container(color: Colors.black54),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.92,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E0E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, -6),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              state.errorMessage == null
                                  ? 'Watchparty wird geladen'
                                  : 'Watchparty konnte nicht geladen werden',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: notifier.closeOverlay,
                              icon: const Icon(Icons.close, color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state.errorMessage != null)
                          Text(
                            state.errorMessage!,
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          )
                        else ...[
                          // CHECK-IN style skeleton
                          const SizedBox(height: 4),
                          Transform.rotate(
                            angle: -0.02,
                            child: const AppSkeletonBox(
                              height: 24,
                              width: 90,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const AppSkeletonBox(height: 36, width: double.infinity),
                          const SizedBox(height: 6),
                          const AppSkeletonBox(height: 36, width: 200),
                          const SizedBox(height: 8),
                          const AppSkeletonBox(height: 16, width: 220),
                          const SizedBox(height: 20),
                          ...List.generate(3, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppSkeletonBox(
                              height: 72,
                              width: double.infinity,
                              borderRadius: BorderRadius.zero,
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activeSessionId = state.activeSession?.sessionId;
    final isActiveSessionOpen =
        activeSessionId == session.sessionId && session.isActive;
    final flowStep = state.flowStep;
    final isLiveStep = flowStep == BingoSessionFlowStep.live;

    if (isLiveStep) {
      _scheduleRunSummaryCheck(session, isActiveSessionOpen);
    }
    if (flowStep == BingoSessionFlowStep.reflection &&
        _inlineSummarySessionId != session.sessionId &&
        !_isRunSummaryOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _presentRunSummary(session, showImmediately: false);
      });
    }

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: notifier.closeOverlay,
            child: Container(color: Colors.black54),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              bottom: false,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: (details) =>
                    _handleDragEnd(details, notifier.closeOverlay),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(0, _dragDy, 0),
                  height: MediaQuery.of(context).size.height * 0.92,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E0E),
                    // border: Border(
                    //   top: BorderSide(
                    //     color: //AppColors.pop.withValues(alpha: 0.55),
                    //     width: 1.2,
                    //   ),
                    // ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(decoration: TextDecoration.none),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(
                              //     horizontal: 16,
                              //     vertical: 4,
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       Container(
                              //         width: 3,
                              //         height: 14,
                              //         color: AppColors.pop,
                              //       ),
                              //       const SizedBox(width: 8),
                              //       Text(
                              //         'BINGO WATCHPARTY',
                              //         style: GoogleFonts.montserrat(
                              //           fontSize: 10,
                              //           fontWeight: FontWeight.w700,
                              //           color: Colors.white54,
                              //           letterSpacing: 1.4,
                              //           decoration: TextDecoration.none,
                              //         ),
                              //       ),
                              //       const SizedBox(width: 6),
                              //       Container(
                              //         padding: const EdgeInsets.symmetric(
                              //           horizontal: 5,
                              //           vertical: 1,
                              //         ),
                              //         decoration: BoxDecoration(
                              //           color: AppColors.pop.withValues(alpha: 0.14),
                              //           borderRadius: BorderRadius.circular(3),
                              //         ),
                              //         child: Text(
                              //           isActiveSessionOpen ? 'LIVE' : 'SESSION',
                              //           style: GoogleFonts.montserrat(
                              //             fontSize: 9,
                              //             fontWeight: FontWeight.w700,
                              //             color: AppColors.pop,
                              //             letterSpacing: 0.6,
                              //             decoration: TextDecoration.none,
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    child: Transform.rotate(
                                      angle: -0.015,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                color: AppColors.secondary,
                                                child: Text(
                                                  'WATCHPARTY',
                                                  style: GoogleFonts.montserrat(
                                                    color:
                                                        const Color(0xFF1E1E1E),
                                                    fontSize: 20,
                                                    height: 1.0,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: -1.0,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                                child: Text(
                                                  'BINGO',
                                                  style: GoogleFonts.montserrat(
                                                    color:
                                                        const Color(0xFF1E1E1E),
                                                    fontSize: 12,
                                                    height: 1.0,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: -1.0,
                                                  ),
                                                ),
                                              ),
                                              Spacer(),
                                              BingoHelpButton(
                                                title:
                                                    'Wie funktioniert Bingo?',
                                                description:
                                                    'Bingo begleitet dich live durch die Episode. Du sammelst typische Momente und Zitate aus genau dieser Folge, bis eine Reihe, Spalte oder Diagonale voll ist.',
                                                usage:
                                                    'Session starten, live beim Schauen abhaken und die Runde nach der Episode wieder über die Historie nachvollziehen.',
                                                accentColor: AppColors.secondary,
                                                steps: const [
                                                  'Starte die Session zu Beginn der Episode oder sobald du aktiv mitschauen willst.',
                                                  'Markiere Felder nur für Ereignisse, die in dieser Folge wirklich passieren.',
                                                  'Wenn eine Reihe, Spalte oder Diagonale voll ist, hast du Bingo erreicht.',
                                                ],
                                                rules: const [
                                                  'Nicht vorgreifen: Ein Feld wird erst gesetzt, wenn der Moment tatsächlich eingetreten ist.',
                                                  'Zitat-Felder zählen nur bei dem echten gesprochenen Satz oder einer sehr klaren Formulierung davon.',
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: AppColors.secondary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  //color: const Color(0xFF090909),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.showTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white,
                                                fontSize: 19,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              flowStep ==
                                                          BingoSessionFlowStep
                                                              .live ||
                                                      flowStep ==
                                                          BingoSessionFlowStep
                                                              .summary
                                                  ? 'Fortschritt: ${session.checkedCount} / ${session.totalCount}'
                                                  : flowStep ==
                                                          BingoSessionFlowStep
                                                              .expectation
                                                      ? 'Before the Drama'
                                                      : flowStep ==
                                                              BingoSessionFlowStep
                                                                  .afterglow
                                                          ? 'Afterglow'
                                                      : 'Deine Story mit der Folge',
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white60,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // IconButton(
                                      //   onPressed: notifier.closeOverlay,
                                      //   padding: EdgeInsets.zero,
                                      //   constraints: const BoxConstraints(
                                      //     minWidth: 32,
                                      //     minHeight: 32,
                                      //   ),
                                      //   visualDensity: VisualDensity.compact,
                                      //   icon: const Icon(Icons.close, color: Colors.white70),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!_showInlineSummary &&
                                  flowStep == BingoSessionFlowStep.live)
                                const _PremiumBingoBanner(),
                              if (state.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    color: Colors.red.withValues(alpha: 0.16),
                                    child: Text(
                                      state.errorMessage!,
                                      style: GoogleFonts.dmSans(
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 420),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    final offset = Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation);
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                          position: offset, child: child),
                                    );
                                  },
                                  child: _buildMainContent(
                                    state: state,
                                    session: session,
                                    isActiveSessionOpen: isActiveSessionOpen,
                                  ),
                                ),
                              ),
                              if (!_showInlineSummary &&
                                  flowStep == BingoSessionFlowStep.live)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 35),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          child: Text(
                                            session.bingoReached
                                                ? 'Bingo erreicht 🎉'
                                                : 'Noch kein Bingo',
                                            style: GoogleFonts.dmSans(
                                              color: session.bingoReached
                                                  ? AppColors.secondary
                                                  : Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Transform.rotate(
                                        angle: -0.012,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isActiveSessionOpen
                                                ? () {
                                                    ref
                                                        .read(
                                                            bingoSessionProvider
                                                                .notifier)
                                                        .openAfterglowStep();
                                                  }
                                                : null,
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              curve: Curves.easeOut,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 9,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isActiveSessionOpen
                                                    ? const Color(0xFFFFE45C)
                                                    : const Color(0xFF2A2A2A),
                                                border:
                                                    const Border.fromBorderSide(
                                                  BorderSide(
                                                    color: Colors.black,
                                                    width: 2,
                                                  ),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha:
                                                                isActiveSessionOpen
                                                                    ? 0.9
                                                                    : 0.45),
                                                    offset: const Offset(3, 3),
                                                    blurRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isActiveSessionOpen
                                                        ? Icons.flag_rounded
                                                        : Icons.history_rounded,
                                                    size: 15,
                                                    color: isActiveSessionOpen
                                                        ? Colors.black
                                                        : Colors.white54,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isActiveSessionOpen
                                                        ? 'FOLGE VORBEI'
                                                        : 'NUR HISTORIE',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      color: isActiveSessionOpen
                                                          ? Colors.black
                                                          : Colors.white54,
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 0.6,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (_isCelebratingBingo)
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: _InlineBingoCelebration(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ), // Material
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Bingo Banner ──────────────────────────────────────────────────────

class _PremiumBingoBanner extends ConsumerWidget {
  const _PremiumBingoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userNotifierProvider).user;
    final waitlistState = ref.watch(premiumWaitlistNotifierProvider);

    if (user != null && !waitlistState.hasChecked && !waitlistState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(premiumWaitlistNotifierProvider.notifier).checkStatus(user.id);
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.10),
          border: const Border(
            left: BorderSide(color: AppColors.secondary, width: 2.5),
          ),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Premium: Bingo-Karten für Love Island & mehr',
                style: GoogleFonts.dmSans(
                  color: AppColors.secondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (waitlistState.isOnWaitlist)
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AppColors.secondary)
            else
              GestureDetector(
                onTap: user == null || waitlistState.isLoading
                    ? null
                    : () => ref
                        .read(premiumWaitlistNotifierProvider.notifier)
                        .joinWaitlist(user.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.secondary.withValues(alpha: 0.22),
                  child: waitlistState.isLoading
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: AppColors.secondary),
                        )
                      : Text(
                          'Vormerken',
                          style: GoogleFonts.montserrat(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            decoration: TextDecoration.none,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecapDeckDots extends StatelessWidget {
  final int index;
  final int count;

  const _RecapDeckDots({
    required this.index,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.secondary.withValues(alpha: 0.9)
                : Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MyJourneyCard extends StatelessWidget {
  final String deckTitle;
  final BingoJourneyPreSummary? journeyPre;
  final String? afterglowEmoji;
  final VoidCallback onShare;

  const _MyJourneyCard({
    required this.deckTitle,
    required this.journeyPre,
    required this.afterglowEmoji,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = _journeyAccuracy(
      preEmoji: journeyPre?.emoji,
      afterglowEmoji: afterglowEmoji,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 55),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: [
            BoxShadow(
              offset: const Offset(2, 2),
              blurRadius: 0,
              color: Colors.black.withValues(alpha: 0.9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deckTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MEINE ERWARTUNG & AFTERGLOW',
                          style: GoogleFonts.dmSans(
                            color: Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: const Icon(
                        Icons.ios_share_rounded,
                        color: Color(0xFFFAF8FF),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Accuracy statement ────────────────────────────────────
              Text(
                accuracy.line1,
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              Text(
                accuracy.line2,
                style: GoogleFonts.montserrat(
                  color: AppColors.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              // ── Divider ───────────────────────────────────────────────
              Container(
                height: 2,
                color: Colors.black,
              ),
              const SizedBox(height: 14),
              // ── Selection label (stamp) ───────────────────────────────
              Center(
                child: Transform.rotate(
                  angle: -0.014, // ~-0.8°
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          color: AppColors.secondary,
                          margin: const EdgeInsets.only(right: 8),
                        ),
                        Text(
                          'DEINE AUSWAHL',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Dimension emojis row ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        journeyPre?.escalationEmoji ?? '—',
                        style: const TextStyle(fontSize: 40, height: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🔥 Eskalation',
                        style: GoogleFonts.montserrat(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        journeyPre?.predictabilityEmoji ?? '—',
                        style: const TextStyle(fontSize: 40, height: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🎲 Überrasch.',
                        style: GoogleFonts.montserrat(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        journeyPre?.scriptednessEmoji ?? '—',
                        style: const TextStyle(fontSize: 40, height: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🎭 Realness',
                        style: GoogleFonts.montserrat(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Divider ───────────────────────────────────────────────
              Container(
                height: 2,
                color: Colors.black,
              ),
              const SizedBox(height: 14),
              // ── Generation label (stamp) ──────────────────────────────
              Center(
                child: Transform.rotate(
                  angle: 0.009, // ~+0.5°
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          color: AppColors.secondary,
                          margin: const EdgeInsets.only(right: 8),
                        ),
                        Text(
                          'ERGIBT DEINE ERWARTUNG',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Hero emoji ────────────────────────────────────────────
              Text(
                journeyPre?.emoji ?? '—',
                style: const TextStyle(fontSize: 60, height: 1.0),
              ),
              const SizedBox(height: 14),
              // ── Divider ───────────────────────────────────────────────
              Container(
                height: 2,
                color: Colors.black,
              ),
              const SizedBox(height: 14),
              // ── Reality label (stamp) ─────────────────────────────────
              Center(
                child: Transform.rotate(
                  angle: -0.011, // ~-0.6°
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          color: AppColors.secondary,
                          margin: const EdgeInsets.only(right: 8),
                        ),
                        Text(
                          'VS. CROWD',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Afterglow emoji ───────────────────────────────────────
              Text(
                afterglowEmoji ?? '—',
                style: const TextStyle(fontSize: 60, height: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreVsCrowdCard extends StatelessWidget {
  final String deckTitle;
  final List<BingoExpectationDimensionReflection> expectationByDimension;
  final Map<String, String> userSelections;
  final VoidCallback onShare;

  const _PreVsCrowdCard({
    required this.deckTitle,
    required this.expectationByDimension,
    required this.userSelections,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _ExpectationMatchSummary.fromData(
      expectationByDimension: expectationByDimension,
      userSelections: userSelections,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 55),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deckTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MEINE ERWARTUNG VOR DER FOLGE',
                          style: GoogleFonts.dmSans(
                            color: Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: const Icon(
                        Icons.ios_share_rounded,
                        color: Color(0xFFFAF8FF),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Hero stamp ────────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Teal offset block behind text
                  Positioned(
                    bottom: -4,
                    left: -3,
                    right: 40,
                    child: Container(
                      height: 14,
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    summary.heroStatement,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 32,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // ── Section label badge ───────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          color: AppColors.secondary,
                          margin: const EdgeInsets.only(right: 8),
                        ),
                        Text(
                          'DEIN TAKE VS. CROWD',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Dimension blocks ──────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: kBingoExpectationDimensions.map((dimension) {
                    BingoExpectationDimensionReflection? reflectionEntry;
                    for (final entry in expectationByDimension) {
                      if (entry.dimension.key == dimension.key) {
                        reflectionEntry = entry;
                        break;
                      }
                    }
                    final userEmoji = userSelections[dimension.key];
                    final sorted = [...(reflectionEntry?.distribution ?? [])]
                      ..sort((a, b) => b.count.compareTo(a.count));
                    final crowdEmoji =
                        sorted.isEmpty ? null : sorted.first.emoji;
                    final isMatch = userEmoji != null &&
                        crowdEmoji != null &&
                        userEmoji == crowdEmoji;
                    final hasData = userEmoji != null && crowdEmoji != null;

                    // Matched blocks: teal bg, black text
                    // Unmatched: white bg, black border
                    final bgColor = isMatch
                        ? AppColors.secondary
                        : const Color(0xFFFFFEFF);
                    final borderColor = Colors.black;
                    final labelColor = Colors.black;
                    final sublabelColor = Colors.black54;

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // Dimension label
                          Expanded(
                            child: Text(
                              _shortDimensionLabel(dimension.key),
                              style: GoogleFonts.montserrat(
                                color: labelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // User emoji + label
                          Column(
                            children: [
                              Text(
                                userEmoji ?? '—',
                                style:
                                    const TextStyle(fontSize: 30, height: 1.0),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ICH',
                                style: GoogleFonts.montserrat(
                                  color: sublabelColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'vs',
                              style: GoogleFonts.montserrat(
                                color: Colors.black38,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          // Crowd emoji + label
                          Column(
                            children: [
                              Text(
                                crowdEmoji ?? '—',
                                style:
                                    const TextStyle(fontSize: 30, height: 1.0),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'CROWD',
                                style: GoogleFonts.montserrat(
                                  color: sublabelColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Match badge
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isMatch
                                  ? Colors.black
                                  : const Color(0xFFFFFEFF),
                              border: Border.all(
                                width: 1.5,
                                color: Colors.black,
                              ),
                            ),
                            child: Icon(
                              isMatch
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              size: 15,
                              color: isMatch
                                  ? AppColors.secondary
                                  : !hasData
                                      ? Colors.black26
                                      : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpectationMatchSummary {
  final int comparedCount;
  final int matchCount;
  final String? strongestDimensionKey;

  const _ExpectationMatchSummary({
    required this.comparedCount,
    required this.matchCount,
    required this.strongestDimensionKey,
  });

  String get heroStatement {
    if (comparedCount == 0) {
      return 'DEIN TAKE.\nNUR DU.\nNOCH KEIN VERGLEICH.';
    }
    if (matchCount == 0) {
      return 'DU SAHST\nDAS KOMPLETT\nANDERS';
    }
    if (matchCount <= 1) {
      return 'DEIN EIGENER\nBLICKWINKEL –\nNICHT CROWD.';
    }
    if (matchCount == comparedCount) {
      return 'VOLLTREFFER –\nDU UND DIE\nCROWD IM SYNC.';
    }
    return '$matchCount VON $comparedCount –\nDU LAGST IM\nCROWD-FLOW.';
  }

  String get bottomLine {
    final focus = switch (strongestDimensionKey) {
      'ESCALATION' => 'Eskalation',
      'SURPRISE' => 'Vorhersehbarkeit',
      'REALNESS' => 'Realness',
      _ => null,
    };

    if (comparedCount == 0) {
      return 'Noch kein Crowd-Vergleich möglich – aber dein Gefühl zählt.';
    }
    if (matchCount == 0) {
      return 'Kein einziger Treffer. Du hast die Folge komplett anders gelesen als alle anderen.';
    }
    if (matchCount == comparedCount) {
      return 'Perfekter Sync. Du hast die Folge genauso gespürt wie die Crowd.';
    }
    if (focus != null) {
      return 'Du warst kritischer als die Crowd – am stärksten bei $focus.';
    }
    return 'Ein eigener Blick. Die Crowd sah das eindeutig anders.';
  }

  static _ExpectationMatchSummary fromData({
    required List<BingoExpectationDimensionReflection> expectationByDimension,
    required Map<String, String> userSelections,
  }) {
    var comparedCount = 0;
    var matchCount = 0;
    var maxGap = -1;
    String? strongestDimensionKey;

    for (final dimension in kBingoExpectationDimensions) {
      final userEmoji = userSelections[dimension.key];
      if (userEmoji == null || userEmoji.isEmpty) continue;

      BingoExpectationDimensionReflection? reflectionEntry;
      for (final entry in expectationByDimension) {
        if (entry.dimension.key == dimension.key) {
          reflectionEntry = entry;
          break;
        }
      }
      if (reflectionEntry == null || reflectionEntry.distribution.isEmpty) {
        continue;
      }

      final sorted = [...reflectionEntry.distribution]
        ..sort((a, b) => b.count.compareTo(a.count));
      final dominantEmoji = sorted.first.emoji;
      comparedCount++;
      if (dominantEmoji == userEmoji) {
        matchCount++;
      }

      final userIndex = _optionIndex(dimension, userEmoji);
      final dominantIndex = _optionIndex(dimension, dominantEmoji);
      if (userIndex == null || dominantIndex == null) continue;
      final gap = (userIndex - dominantIndex).abs();
      if (gap > maxGap) {
        maxGap = gap;
        strongestDimensionKey = dimension.key;
      }
    }

    return _ExpectationMatchSummary(
      comparedCount: comparedCount,
      matchCount: matchCount,
      strongestDimensionKey: strongestDimensionKey,
    );
  }
}

class _PostVsCrowdCard extends StatelessWidget {
  final String deckTitle;
  final List<BingoEmotionAggregate> afterglowEntries;
  final String? afterglowEmoji;
  final VoidCallback onShare;

  const _PostVsCrowdCard({
    required this.deckTitle,
    required this.afterglowEntries,
    required this.afterglowEmoji,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...afterglowEntries]..sort((a, b) => b.count.compareTo(a.count));
    final visible = _pickCloudEntries(
      sorted,
      afterglowEmoji,
      maxEntries: 8,
    );
    final mood = _postCrowdMood(
      entries: sorted,
      userEmoji: afterglowEmoji,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 55),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deckTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MEIN GEFÜHL NACH DER FOLGE',
                          style: GoogleFonts.dmSans(
                            color: Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: const Icon(
                        Icons.ios_share_rounded,
                        color: Color(0xFFFAF8FF),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // ── Hero + subline ────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: -4,
                    left: -3,
                    right: 40,
                    child: Container(
                      height: 14,
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    mood.heroLine,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 32,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                mood.heroSubline,
                style: GoogleFonts.dmSans(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // ── Section label ─────────────────────────────────────────
              // Row(
              //   children: [
              //     Container(
              //       width: 3,
              //       height: 12,
              //       color: AppColors.secondary,
              //     ),
              //     const SizedBox(width: 8),
              //     Text(
              //       'CROWD STIMMUNG',
              //       style: GoogleFonts.montserrat(
              //         color: Colors.black45,
              //         fontSize: 10,
              //         fontWeight: FontWeight.w800,
              //         letterSpacing: 1.8,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 14),
              // ── Emotion cloud ─────────────────────────────────────────
              Expanded(
                child: _AfterglowEmotionCloud(
                  entries: visible,
                  userEmoji: afterglowEmoji,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mood.microInsight,
                style: GoogleFonts.dmSans(
                  color: Colors.black54,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AfterglowEmotionCloud extends StatelessWidget {
  final List<BingoEmotionAggregate> entries;
  final String? userEmoji;

  const _AfterglowEmotionCloud({
    required this.entries,
    required this.userEmoji,
  });

  static const double _cloudHeight = 292;
  static const List<(double, double)> _positions = [
    (0.49, 0.34),
    (0.24, 0.20),
    (0.74, 0.24),
    (0.18, 0.56),
    (0.80, 0.60),
    (0.49, 0.73),
    (0.34, 0.88),
    (0.66, 0.86),
  ];

  static const List<double> _xDrift = [0, -10, 12, -8, 10, 0, -6, 8];
  static const List<double> _yDrift = [0, -7, -3, 5, 8, 12, 10, 14];
  static const List<double> _tilt = [0.0, -0.08, 0.07, -0.06, 0.05, -0.03, 0.04, -0.05];

  static double _emojiSize(double share) {
    final size = 26.0 + sqrt(share.clamp(0.0, 1.0)) * 88.0;
    return size.clamp(34.0, 94.0);
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        height: 180,
        alignment: Alignment.center,
        color: Colors.black.withValues(alpha: 0.02),
        child: Text(
          'Noch nicht genug Crowd-Stimmen.',
          style: GoogleFonts.dmSans(
            color: Colors.black38,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final sorted = [...entries]..sort((a, b) => b.count.compareTo(a.count));

    return SizedBox(
      width: double.infinity,
      height: _cloudHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < sorted.length && i < _positions.length; i++)
                Builder(
                  builder: (context) {
                    final entry = sorted[i];
                    final isUser = userEmoji != null && entry.emoji == userEmoji;
                    final (fx, fy) = _positions[i];
                    final emojiSize = _emojiSize(entry.share);
                    final bubbleSize = emojiSize + 22;
                    final left =
                        (fx * w - bubbleSize / 2 + _xDrift[i]).clamp(0.0, w - bubbleSize);
                    final top = (fy * _cloudHeight - bubbleSize / 2 + _yDrift[i])
                        .clamp(0.0, _cloudHeight - bubbleSize - 14);

                    return Positioned(
                      left: left,
                      top: top,
                      child: Column(
                        children: [
                          Transform.rotate(
                            angle: _tilt[i],
                            child: Container(
                              width: bubbleSize,
                              height: bubbleSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.secondary
                                    : const Color(0xFFFFFEFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                entry.emoji,
                                style: TextStyle(fontSize: emojiSize, height: 1.0),
                              ),
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(height: 4),
                            Text(
                              'DAS WAR DEIN GEFÜHL',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RunSummaryDeckCard extends StatelessWidget {
  final String deckTitle;
  final BingoRunSummaryData? summaryData;
  final List<BingoBoardItem> checkedItems;
  final VoidCallback onShare;
  final VoidCallback onShareBoard;
  final VoidCallback onPlayAgain;
  final VoidCallback onViewRuns;
  final VoidCallback onViewRanking;

  const _RunSummaryDeckCard({
    required this.deckTitle,
    required this.summaryData,
    required this.checkedItems,
    required this.onShare,
    required this.onShareBoard,
    required this.onPlayAgain,
    required this.onViewRuns,
    required this.onViewRanking,
  });

  @override
  Widget build(BuildContext context) {
    final showPercentileSegment = summaryData?.percentileBeat != null;

    return _RecapStoryCard(
      title: deckTitle,
      heroLine: summaryData == null
          ? 'Dein Ergebnis\nwird geladen.'
          : (summaryData!.bingoAchieved
              ? 'BINGO.\nSTARKER RUN.'
              : 'KEIN BINGO.\nNÄCHSTES MAL.'),
      accentColor: const ui.Color.fromARGB(255, 255, 255, 255),
      backgroundColor: const ui.Color.fromARGB(255, 32, 32, 32),
      showBlob: false,
      onShare: onShare,
      onShareBoard: onShareBoard,
      child: summaryData == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Summary wird vorbereitet ...',
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BingoRunSummarySheet(
                  embedded: true,
                  data: summaryData!,
                  showPercentileSection: showPercentileSegment,
                  onPlayAgain: onPlayAgain,
                  onViewRuns: onViewRuns,
                  onViewRanking: onViewRanking,
                ),
                // ── Top 3 checked fields ────────────────────────────
                if (checkedItems.isNotEmpty && !showPercentileSegment)
                  ..._buildTopFields(context),
                const SizedBox(height: 16),
                // ── Prominent board share CTA ────────────────────────
                GestureDetector(
                  onTap: onShareBoard,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(4, 4),
                          blurRadius: 0,
                          color: Color(0xFFFFE600),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dashboard_outlined, color: Color(0xFFFFE600), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'MEIN BOARD TEILEN',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  List<Widget> _buildTopFields(BuildContext context) {
    final sorted = [...checkedItems]..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    final top3 = sorted.take(3).toList();
    return [
      Text(
        'DEINE TOP-FELDER',
        style: GoogleFonts.montserrat(
          color: Colors.black54,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 6),
      Column(
        children: top3.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE600),
                    border: Border(
                      top: BorderSide(color: Colors.black, width: idx == 0 ? 1.5 : 0),
                      left: const BorderSide(color: Colors.black, width: 1.5),
                      bottom: const BorderSide(color: Colors.black, width: 1.5),
                      right: BorderSide.none,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${idx + 1}',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8FF),
                      border: Border(
                        top: BorderSide(color: Colors.black, width: idx == 0 ? 1.5 : 0),
                        left: const BorderSide(color: Colors.black, width: 1.5),
                        right: const BorderSide(color: Colors.black, width: 1.5),
                        bottom: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.phrase,
                            style: GoogleFonts.dmSans(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.checkedAt != null) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 10,
                                color: Colors.black45,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatCheckedTime(context, item.checkedAt!),
                                style: GoogleFonts.dmSans(
                                  color: Colors.black45,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ];
  }

  String _formatCheckedTime(BuildContext context, DateTime checkedAt) {
    final tod = TimeOfDay.fromDateTime(checkedAt);
    return tod.format(context);
  }
}

class _RecapStoryCard extends StatelessWidget {
  final String title;
  final String heroLine;
  final Color accentColor;
  final Color backgroundColor;
  final bool showBlob;
  final bool showHero;
  final bool showHeroAccent;
  final Color? heroLine1Color;
  final Color? heroLine2Color;
  final VoidCallback onShare;
  final VoidCallback? onShareBoard;
  final Widget child;

  const _RecapStoryCard({
    required this.title,
    required this.heroLine,
    required this.accentColor,
    required this.backgroundColor,
    this.showBlob = false,
    this.showHero = true,
    this.showHeroAccent = true,
    this.heroLine1Color,
    this.heroLine2Color,
    required this.onShare,
    this.onShareBoard,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 55),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: [
            BoxShadow(
              offset: const Offset(2, 2),
              blurRadius: 0,
              color: Colors.black.withValues(alpha: 0.9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BINGO-ERGEBNIS',
                            style: GoogleFonts.dmSans(
                              color: Colors.black38,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onShare,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: const Icon(
                              Icons.ios_share_rounded,
                              color: Color(0xFFFAF8FF),
                              size: 18,
                            ),
                          ),
                        ),
                        if (onShareBoard != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onShareBoard,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              child: const Icon(
                                Icons.dashboard_outlined,
                                color: Color(0xFFFAF8FF),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (showHero) ...[
                  const SizedBox(height: 18),
                  if (showHeroAccent)
                    // ── Hero text with teal accent ─────────────────────────
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: -4,
                          left: -3,
                          right: 40,
                          child: Container(
                            height: 14,
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        Text(
                          heroLine,
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 32,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.8,
                          ),
                        ),
                      ],
                    )
                  else
                    // ── Split-color hero text (no accent bar) ─────────────
                    Builder(builder: (context) {
                      final lines = heroLine.split('\n');
                      final c1 = heroLine1Color ?? Colors.black;
                      final c2 = heroLine2Color ?? Colors.black;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < lines.length; i++)
                            Text(
                              lines[i],
                              style: GoogleFonts.montserrat(
                                color: i == 0 ? c1 : c2,
                                fontSize: 32,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.8,
                              ),
                            ),
                        ],
                      );
                    }),
                  const SizedBox(height: 22),
                ] else
                  const SizedBox(height: 8),
                // // ── Section stamp ──────────────────────────────────────
                // Center(
                //   child: Transform.rotate(
                //     angle: -0.009,
                //     child: Container(
                //       decoration: BoxDecoration(
                //         color: Colors.black,
                //         border: Border.all(color: Colors.black, width: 1.5),
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.black.withValues(alpha: 0.6),
                //             offset: const Offset(3, 3),
                //             blurRadius: 0,
                //           ),
                //         ],
                //       ),
                //       padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Container(
                //             width: 3,
                //             height: 14,
                //             color: AppColors.secondary,
                //             margin: const EdgeInsets.only(right: 8),
                //           ),
                //           Text(
                //             'MEIN BINGO-ERGEBNIS',
                //             style: GoogleFonts.montserrat(
                //               color: Colors.white,
                //               fontSize: 10,
                //               fontWeight: FontWeight.w800,
                //               letterSpacing: 1.8,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                //const SizedBox(height: 5),
                // ── Content ────────────────────────────────────────────
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Journey accuracy header ──────────────────────────────────────────────────

({String line1, String line2, Color accentColor}) _journeyAccuracy({
  required String? preEmoji,
  required String? afterglowEmoji,
}) {
  if (preEmoji == null || afterglowEmoji == null) {
    return (
      line1: 'DEINE',
      line2: 'JOURNEY',
      accentColor: const Color(0xFFDCCAE5),
    );
  }

  const highEnergy = {'🔥', '🤯'};
  const lowEnergy = {'🧊', '🙄'};

  String groupOf(String emoji) {
    if (highEnergy.contains(emoji)) return 'high';
    if (lowEnergy.contains(emoji)) return 'low';
    return 'mid';
  }

  final preGroup = groupOf(preEmoji);
  final postGroup = groupOf(afterglowEmoji);

  if (preGroup == postGroup) {
    return (
      line1: 'DU HATTEST DEN',
      line2: 'RICHTIGEN RIECHER',
      accentColor: const Color(0xFFFF6B6B),
    );
  }
  if ((preGroup == 'high' && postGroup == 'low') ||
      (preGroup == 'low' && postGroup == 'high')) {
    return (
      line1: 'REALITY IST',
      line2: 'UNVORHERSEHBAR',
      accentColor: const Color(0xFFFF6B6B),
    );
  }
  return (
    line1: 'DU WEIßT WORAUF',
    line2: 'DU DICH EINLÄSST',
    accentColor: const Color(0xFFFF6B6B),
  );
}

List<BingoEmotionAggregate> _pickCloudEntries(
  List<BingoEmotionAggregate> entries,
  String? userEmoji,
  {int maxEntries = 6,
  }
) {
  if (entries.isEmpty) return const [];
  final top = entries.take(maxEntries).toList();
  if (userEmoji == null || userEmoji.isEmpty) return top;
  final alreadyIncluded = top.any((entry) => entry.emoji == userEmoji);
  if (alreadyIncluded) return top;

  BingoEmotionAggregate? userEntry;
  for (final entry in entries) {
    if (entry.emoji == userEmoji) {
      userEntry = entry;
      break;
    }
  }
  if (userEntry == null) return top;

  if (top.length < maxEntries) {
    return [...top, userEntry];
  }

  top[top.length - 1] = userEntry;
  return top;
}

String _buildRecapDeckTitle(BingoSessionView session) {
  final title = session.showTitle.trim().toUpperCase();
  final seasonToken = (session.seasonNumber != null && session.seasonNumber! > 0)
      ? 'S${session.seasonNumber}'
      : 'SX';
  final episodeToken = (session.episodeNumber != null && session.episodeNumber! > 0)
      ? 'E${session.episodeNumber}'
      : 'EX';
  return '$title • $seasonToken$episodeToken';
}

String _shortDimensionLabel(String key) {
  return switch (key) {
    'ESCALATION' => '🔥 Eskalation',
    'SURPRISE' => '🎲 Überraschung',
    'REALNESS' => '🎭 Realness',
    _ => key,
  };
}

int? _optionIndex(BingoExpectationDimension dimension, String emoji) {
  for (var i = 0; i < dimension.options.length; i++) {
    if (dimension.options[i].emoji == emoji) return i;
  }
  return null;
}

({String heroLine, String heroSubline, String microInsight}) _postCrowdMood({
  required List<BingoEmotionAggregate> entries,
  required String? userEmoji,
}) {
  if (entries.isEmpty || userEmoji == null || userEmoji.isEmpty) {
    return (
      heroLine: 'DEIN GEFÜHL\nHAT DEN TON\nGESETZT',
      heroSubline: 'im Vergleich zur Crowd',
      microInsight: 'Noch nicht genug Crowd-Daten für einen klaren Vergleich.',
    );
  }

  final dominant = entries.first.emoji;
  final userScore = _afterglowIntensityScore(userEmoji);
  final crowdScore = _afterglowIntensityScore(dominant);

  if (userScore == crowdScore) {
    return (
      heroLine: 'EINE WELLENLÄNGE\nMIT DER CROWD',
      heroSubline: '',
      microInsight: 'Dein Gefühl nach der Folge war ähnlich intensiv wie das der anderen.',
    );
  }

  final userMoreIntense = userScore > crowdScore;
  return (
    heroLine: userMoreIntense ? 'DU WARST\nINTENSIVER' : 'DU WARST\nENTSPANNTER',
    heroSubline: 'als die Crowd',
    microInsight: userMoreIntense
        ? 'Für dich war die Folge heftiger als für die meisten.'
        : 'Für dich war die Folge ruhiger als für die meisten.',
  );
}

int _afterglowIntensityScore(String emoji) {
  switch (emoji) {
    case '🤯':
      return 5;
    case '🔥':
      return 4;
    case '😬':
      return 3;
    case '😢':
      return 2;
    case '🙄':
      return 1;
    case '🧊':
      return 0;
    default:
      return 2;
  }
}

class _EpisodeRecapCard extends StatelessWidget {
  final String deckTitle;
  final BingoEpisodeRecapView? recapData;
  final VoidCallback onShare;

  const _EpisodeRecapCard({
    required this.deckTitle,
    required this.recapData,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return _RecapStoryCard(
      title: deckTitle,
      heroLine: recapData == null
          ? 'Community\nHeat Loading'
          : 'TOP MOMENTE\nDER EPISODE',
      accentColor: const ui.Color.fromARGB(255, 255, 255, 255),
      backgroundColor: const ui.Color.fromARGB(255, 32, 32, 32),
      showBlob: false,
      showHeroAccent: false,
      heroLine1Color: AppColors.secondary,
      heroLine2Color: Colors.black,
      onShare: onShare,
      child: recapData == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Top-Momente werden gesammelt ...',
                      style: GoogleFonts.dmSans(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recapData!.isLowDataSample)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade700, width: 2),
                        color: Colors.orange.shade50,
                      ),
                      child: Text(
                        'Noch früh, aber Bingo wird schon gehämmert 🔨',
                        style: GoogleFonts.dmSans(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (recapData!.isLowDataSample) const SizedBox(height: 12),
                  Text(
                    'Community Bingo-Rate',
                    style: GoogleFonts.dmSans(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${(recapData!.bingoRate * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.montserrat(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'für ${recapData!.totalSessions} Sessions',
                        style: GoogleFonts.dmSans(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Top ${recapData!.topMoments.length} Felder',
                    style: GoogleFonts.dmSans(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    recapData!.topMoments.length,
                    (index) {
                      final moment = recapData!.topMoments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const ui.Color(0xFFFFE600),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    moment.phrase,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${moment.clickCount} Klicks',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.black45,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _CommunityBoardHeatmapCard extends StatelessWidget {
  final String deckTitle;
  final BingoCommunityBoardHeatmap? heatmapData;
  final VoidCallback onShare;

  const _CommunityBoardHeatmapCard({
    required this.deckTitle,
    required this.heatmapData,
    required this.onShare,
  });

  Color _getHeatmapColor(double relativeFrequency) {
    if (relativeFrequency == 0) {
      return const Color(0xFFE3E3E3);
    }
    if (relativeFrequency < 0.05) {
      return const Color(0xFFD6D6D6);
    }
    if (relativeFrequency < 0.1) {
      return AppColors.secondary.withValues(alpha: 0.18);
    }
    if (relativeFrequency < 0.15) {
      return AppColors.secondary.withValues(alpha: 0.32);
    }
    if (relativeFrequency < 0.2) {
      return AppColors.secondary.withValues(alpha: 0.5);
    }
    return AppColors.secondary.withValues(alpha: 0.72);
  }

  @override
  Widget build(BuildContext context) {
    return _RecapStoryCard(
      title: deckTitle,
      heroLine: heatmapData == null
          ? 'Heatmap\nLoading'
          : 'BINGO HEATMAP',
      accentColor: const ui.Color.fromARGB(255, 255, 255, 255),
      backgroundColor: const ui.Color.fromARGB(255, 32, 32, 32),
      showBlob: false,
      showHero: false,
      onShare: onShare,
      child: heatmapData == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Heatmap wird berechnet ...',
                      style: GoogleFonts.dmSans(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Transform.rotate(
                      angle: -0.02,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          'COMMUNITY HEATMAP',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (heatmapData!.isLowDataSample)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade700, width: 2),
                        color: Colors.orange.shade50,
                      ),
                      child: Text(
                        'Noch zu früh, aber Muster entstehen 🔬',
                        style: GoogleFonts.dmSans(
                          color: Colors.orange.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (heatmapData!.isLowDataSample) const SizedBox(height: 8),
                  // Text(
                  //   'Gesamt: ${heatmapData!.totalClicks} Klicks über ${heatmapData!.totalSessions} Sessions',
                  //   style: GoogleFonts.dmSans(
                  //     color: Colors.black54,
                  //     fontSize: 9,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  _buildBoardGrid(heatmapData!.entries),
                ],
              ),
            ),
    );
  }

  Widget _buildBoardGrid(List<BingoCommunityBoardHeatmapEntry> entries) {
    if (entries.isEmpty) {
      return const Center(child: Text('Keine Daten'));
    }

    // Bestimme Grid-Größe basierend auf Einträgen
    int gridSize = 5; // Standard: 5x5
    if (entries.length == 16) gridSize = 4; // Fallback für 4x4
    if (entries.length == 9) gridSize = 3; // Fallback für 3x3

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final cellWidth = availableWidth / gridSize;
        final cellHeight = cellWidth / 0.75;
        final boardHeight = cellHeight * gridSize;

        return SizedBox(
          height: boardHeight,
          child: GridView.builder(
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final bgColor = _getHeatmapColor(entry.relativeFrequency);
              final textColor = entry.relativeFrequency >= 0.15
                ? Colors.black
                : Colors.black87;
              final badgeTextColor = Colors.white;
              final borderColor = entry.relativeFrequency > 0
                ? AppColors.secondary.withValues(alpha: 0.78)
                : const Color(0xFFC8C8C8);

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: entry.relativeFrequency > 0 ? 1.6 : 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${entry.clickCount}',
                            style: GoogleFonts.montserrat(
                              color: badgeTextColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Center(
                          child: Text(
                            entry.phrase,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _UserBingoBoardShareWidget extends StatelessWidget {
  final BingoSessionView session;

  const _UserBingoBoardShareWidget({required this.session});

  double _adaptiveGridFontSize(String phrase, int gridSize) {
    int score = 15;
    if (phrase.length > 25) score -= 2;
    if (phrase.length > 30) score -= 2;
    if (phrase.length > 35) score -= 2;
    if (gridSize >= 5) score += 8;
    if (gridSize <= 3) score -= 4;
    return score.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MEIN WATCHPARTY\nBINGO BOARD',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${session.checkedCount} / ${session.totalCount} Felder',
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              primary: false,
              itemCount: session.boardItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: session.gridSize,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemBuilder: (context, index) {
                final item = session.boardItems[index];
                final cellBgColor = item.checked
                    ? const ui.Color.fromARGB(159, 46, 74, 77)
                    : const Color(0xFF171717);
                final cellBorderColor = item.checked
                    ? const Color(0xFF7FAEB0)
                    : const Color(0xFF2B2B2B);

                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cellBgColor,
                    border: Border.all(
                      color: cellBorderColor,
                      width: item.checked ? 2.1 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: item.checked ? 0.55 : 0.35,
                        ),
                        offset: const Offset(1, 1),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item.phrase,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: _adaptiveGridFontSize(
                          item.phrase,
                          session.gridSize,
                        ),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const ui.Color(0xFFFFE600), width: 2),
              color: const ui.Color(0xFFFFE600).withValues(alpha: 0.1),
            ),
            child: Text(
              '${session.bingoReached ? '🎰 BINGO!' : '💪 Keep going!'}  Teile dein Board und mach die Community heiß!',
              style: GoogleFonts.dmSans(
                color: const ui.Color(0xFFFFE600),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBingoCelebration extends StatefulWidget {
  const _InlineBingoCelebration();

  @override
  State<_InlineBingoCelebration> createState() =>
      _InlineBingoCelebrationState();
}

class _InlineBingoCelebrationState extends State<_InlineBingoCelebration>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 2400);
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..forward();

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 56),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 26,
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.86, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 34,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 66,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.secondary.withValues(alpha: 0.14),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.34),
          ],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Transform.rotate(
                  angle: -0.02,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -8,
                        left: -8,
                        child: Transform.rotate(
                          angle: 0.03,
                          child: Container(
                            width: 92,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE45C),
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.black, width: 2),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'BINGO',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.black, width: 3),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black, offset: Offset(6, 6)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.black),
                            const SizedBox(width: 10),
                            Text(
                              'BINGO!',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AutoScrollingPhraseText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _AutoScrollingPhraseText({
    required this.text,
    required this.style,
  });

  @override
  State<_AutoScrollingPhraseText> createState() =>
      _AutoScrollingPhraseTextState();
}

class _AutoScrollingPhraseTextState extends State<_AutoScrollingPhraseText> {
  static const Duration _initialPause = Duration(milliseconds: 1400);
  static const Duration _bottomPause = Duration(milliseconds: 1000);
  static const Duration _restartPause = Duration(milliseconds: 500);

  final ScrollController _scrollController = ScrollController();
  int _animationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scheduleCycleRestart();
  }

  @override
  void didUpdateWidget(covariant _AutoScrollingPhraseText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _scheduleCycleRestart();
    }
  }

  @override
  void dispose() {
    _animationGeneration++;
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCycleRestart() {
    _animationGeneration++;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
      _startCycle(_animationGeneration);
    });
  }

  Future<void> _startCycle(int generation) async {
    while (mounted && generation == _animationGeneration) {
      if (!_scrollController.hasClients) {
        return;
      }

      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        return;
      }

      await Future<void>.delayed(_initialPause);
      if (!mounted || generation != _animationGeneration) {
        return;
      }

      final duration = Duration(
        milliseconds: (maxExtent * 28).clamp(1800, 5200).round(),
      );

      await _scrollController.animateTo(
        maxExtent,
        duration: duration,
        curve: Curves.easeInOut,
      );
      if (!mounted || generation != _animationGeneration) {
        return;
      }

      await Future<void>.delayed(_bottomPause);
      if (!mounted || generation != _animationGeneration) {
        return;
      }

      _scrollController.jumpTo(0);
      await Future<void>.delayed(_restartPause);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          locale: const Locale('de', 'DE'),
          softWrap: true,
          style: widget.style,
        ),
      ),
    );
  }
}
