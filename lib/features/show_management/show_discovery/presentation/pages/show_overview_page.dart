import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/bingo_management/presentation/widgets/bingo_floating_button.dart';
import 'package:frontend/features/premium_management/presentation/widgets/premium_tease_block.dart';
import 'package:frontend/features/bingo_management/presentation/widgets/bingo_overlay_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/next_calendar_event_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/upcoming_calendar_events_list_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../favorites_management/presentation/providers/favorites_provider.dart';
import '../../../../user_management/presentation/providers/user_provider.dart';
import '../providers/show_overview_provider.dart';
import '../widgets/show_creator_events_section_widget.dart';
import '../widgets/show_overview_release_window_widget.dart';
import '../widgets/show_overview_season_list_widget.dart';
import '../widgets/show_overview_title_widget.dart';
import '../widgets/show_social_section_widget.dart';
import '../widgets/show_trash_events_section_widget.dart';

class ShowOverviewPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowOverviewPage({super.key, required this.showId});

  @override
  ConsumerState<ShowOverviewPage> createState() => _ShowOverviewPageState();
}

class _ShowOverviewPageState extends ConsumerState<ShowOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Color _parseThemeColor(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return AppColors.pop;
    }

    var hex = cleaned.replaceAll('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return const Color(0xFFE5ADFF);
    }
    return Color(parsed);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(showOverviewProvider.notifier).loadShow(widget.showId);
    });
  }

  @override
  void didUpdateWidget(covariant ShowOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(showOverviewProvider.notifier).loadShow(widget.showId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showOverviewProvider);

    if (show.isLoading || show.id != widget.showId) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: SafeArea(child: _ShowOverviewSkeleton()),
      );
    }

    final themeColor = _parseThemeColor(show.mainColor);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF0F0F0F),
                  Color(0xFF141414),
                  Color(0xFF0F0F0F),
                ],
              ),
            ),
            child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ShowOverviewTitleWidget(
                title: show.title,
                genre: show.genre,
                showId: widget.showId,
                headerImageUrl: show.headerImageUrl,
                accentColor: themeColor,
                showTopActions: false,
              ),
              const SizedBox(height: 10),
              if (show.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: ClipRRect(
                    //borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            left: BorderSide(color: themeColor, width: 3),
                          ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ÜBER DIE SHOW',
                            style: GoogleFonts.montserrat(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            show.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (show.releaseWindow.trim().isNotEmpty)
                ReleaseWindowWidget(
                  releaseWindow: show.releaseWindow,
                  accentColor: themeColor,
                ),
              //SeasonSelectorWidget(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                child: ShowSocialSection(showId: widget.showId, accentColor: themeColor),
              ),
              NextCalendarEventWidget(showId: widget.showId, accentColor: themeColor),
              UpcomingCalendarEventsListWidget(showId: widget.showId, accentColor: themeColor),
              // ── Block 2: Creator Content ──────────────────────────────────

              SeasonListWidget(showId: widget.showId, accentColor: themeColor),
              ShowCreatorEventsSection(showId: widget.showId, accentColor: themeColor),
              // ── Block 3: Trash & Community Events ─────────────────────────
              ShowTrashEventsSection(showId: widget.showId, accentColor: themeColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: PremiumTeaseBlock(
                  lockedItems: const [
                    PremiumLockedItem(emoji: '📈', label: 'Community-Bewertung dieser Show'),
                    PremiumLockedItem(emoji: '⏱️', label: 'Ø Bingo-Zeit aller Zuschauer'),
                    PremiumLockedItem(emoji: '🏆', label: 'Dein Ranking unter Fans'),
                  ],
                ),
              ),
              const SizedBox(height: 45), // Abstand am Ende
            ],
          ),
        ),
        ),
        _PinnedShowOverviewTopBar(
          showId: widget.showId,
          showTitle: show.title,
          accentColor: themeColor,
        ),
        const BingoFloatingButton(bottomOffset: 20),
        const BingoOverlayWidget(),
      ],
    );
  }
}

class _PinnedShowOverviewTopBar extends ConsumerStatefulWidget {
  final String showId;
  final String showTitle;
  final Color accentColor;

  const _PinnedShowOverviewTopBar({
    required this.showId,
    required this.showTitle,
    required this.accentColor,
  });

  @override
  ConsumerState<_PinnedShowOverviewTopBar> createState() =>
      _PinnedShowOverviewTopBarState();
}

class _PinnedShowOverviewTopBarState
    extends ConsumerState<_PinnedShowOverviewTopBar> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFavorite());
  }

  Future<void> _checkIfFavorite() async {
    final userState = ref.read(userNotifierProvider);
    final userId = userState.user?.id;
    if (userId == null) return;

    final isFavoriteShow = ref.read(isFavoriteShowProvider);
    final isFavorite = await isFavoriteShow(userId, widget.showId);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    final userState = ref.read(userNotifierProvider);
    final user = userState.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte loggen Sie sich ein, um Favoriten hinzuzufuegen'),
        ),
      );
      return;
    }

    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
    if (_isFavorite) {
      await favoritesNotifier.removeShowFromFavorites(user.id, widget.showId);
    } else {
      await favoritesNotifier.addShowToFavorites(
        user.id,
        widget.showId,
        widget.showTitle,
      );
    }

    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userNotifierProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: topInset + 52,
        padding: EdgeInsets.only(top: topInset),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? widget.accentColor : Colors.black54,
                  ),
                  onPressed: _toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.black54),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowOverviewSkeleton extends StatelessWidget {
  const _ShowOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        AppSkeletonBox(
          width: double.infinity,
          height: 290,
          borderRadius: BorderRadius.zero,
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppSkeletonLines(lines: 4, height: 12, widths: [0.9, 1, 0.95, 0.45]),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppSkeletonBox(height: 44),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppSkeletonBox(height: 60),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppSkeletonBox(height: 140),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppSkeletonBox(height: 140),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AppSkeletonBox(height: 220),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}
