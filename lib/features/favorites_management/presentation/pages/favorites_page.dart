import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/providers/streaming_filter_provider.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/core/widgets/not_logged_in_widget.dart';
import 'package:frontend/core/widgets/top_bar_widget.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/favorites_management/presentation/providers/recommendations_provider.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_creator_button.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/premium_management/presentation/widgets/premium_tease_block.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: TopBarWidget(),
      body: userState.isLoading
          ? const _FavoritesPageSkeleton()
          : userState.user == null
              ? Center(child: NotLoggedInWidget())
              : _FavoritesBody(userId: userState.user!.id),
    );
  }
}

// ─── Main scrollable body ────────────────────────────────────────────────────

class _FavoritesBody extends ConsumerStatefulWidget {
  final String userId;

  const _FavoritesBody({required this.userId});

  @override
  _FavoritesBodyState createState() => _FavoritesBodyState();
}

class _FavoritesBodyState extends ConsumerState<_FavoritesBody> {
  _FavoritesNav _activeNav = _FavoritesNav.favorites;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesNotifierProvider.notifier)
          .fetchFavoriteShows(widget.userId);
      ref.read(favoritesNotifierProvider.notifier)
          .fetchFavoriteCreators(widget.userId);
      ref
          .read(streamingServiceFilterProvider.notifier)
          .loadForUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoritesNotifierProvider);

    return Column(
      children: [
        // ── Page title (same structure as CalendarPage) ─────────────────────
        SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            color: AppColors.pop,
                            child: Text(
                              'DEIN BEREICH',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF1E1E1E),
                                fontSize: 28,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        // ── Scrollable content ───────────────────────────────────────────────
        Expanded(
          child: CustomScrollView(
            slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NavChip(
                    label: 'Favoriten',
                    isSelected: _activeNav == _FavoritesNav.favorites,
                    onTap: () => setState(() => _activeNav = _FavoritesNav.favorites),
                  ),
                  const SizedBox(width: 8),
                  _NavChip(
                    label: 'Aktivitäten',
                    isSelected: _activeNav == _FavoritesNav.activities,
                    onTap: () => setState(() => _activeNav = _FavoritesNav.activities),
                  ),
                  const SizedBox(width: 8),
                  _NavChip(
                    label: 'Filter',
                    isSelected: _activeNav == _FavoritesNav.filter,
                    onTap: () => setState(() => _activeNav = _FavoritesNav.filter),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        if (_activeNav == _FavoritesNav.filter) ...[
          SliverToBoxAdapter(
            child: _StreamingFilterSection(userId: widget.userId),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],

        if (_activeNav == _FavoritesNav.favorites) ...[
          // ── ❤️ Deine Favoriten (show list) ─────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(label: '❤️  Deine Favoriten'),
          ),

          if (favState.isLoading)
            const SliverToBoxAdapter(child: _FavoritesListSkeleton())
          else if (favState.favoriteShows.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Noch keine Favoriten.',
                      style: GoogleFonts.dmSans(
                          color: Colors.white54, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tippe das ❤️ bei deiner Lieblingsshow.',
                      style: GoogleFonts.dmSans(
                          color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final show = favState.favoriteShows[index];
                  return GestureDetector(
                    onTap: () => context
                        .push('${AppRoutes.showOverview}/${show.showId}'),
                    child: Container(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 1),
                      child: Row(
                        children: [
                          // Pop accent bar
                          Container(width: 4, height: 56, color: AppColors.pop),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              show.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Open show arrow
                          const Icon(Icons.chevron_right,
                              color: Colors.white24, size: 18),
                          // Heart button to un-favorite
                          FavoriteHeartButton(
                            showId: show.showId,
                            showTitle: show.displayTitle,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  );
                },
                childCount: favState.favoriteShows.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 🎬 Deine Creator ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(label: '🎬  Deine Creator'),
          ),

          if (favState.favoriteCreators.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Noch keine Creator favorisiert.',
                      style: GoogleFonts.dmSans(
                          color: Colors.white54, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tippe das ❤️ auf einer Creator-Seite.',
                      style: GoogleFonts.dmSans(
                          color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final creator = favState.favoriteCreators[index];
                  return GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      context.push(
                        AppRoutes.creatorDetail,
                        extra: ResolvedCalendarEvent(
                          calendarEventId: 'favorite_creator_${creator.creatorId}',
                          startDatetime: now,
                          endDatetime: now,
                          isShowEvent: false,
                          isCreatorEvent: true,
                          isTrashEvent: false,
                          creatorId: creator.creatorId,
                          creatorName: creator.name,
                        ),
                      );
                    },
                    child: Container(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 1),
                      child: Row(
                        children: [
                          Container(
                              width: 4,
                              height: 56,
                              color: const Color(0xFF4DB6FF)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              creator.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.white24, size: 18),
                          FavoriteCreatorButton(
                            creatorId: creator.creatorId,
                            creatorName: creator.name,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  );
                },
                childCount: favState.favoriteCreators.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 💎 Premium Teaser ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PremiumTeaseBlock(
                lockedItems: const [
                  PremiumLockedItem(emoji: '📊', label: 'Show-Statistiken im Überblick'),
                  PremiumLockedItem(emoji: '🔔', label: 'Neue Episoden-Alerts (automatisch)'),
                  PremiumLockedItem(emoji: '🧬', label: 'Dein persönliches Binge-Profil'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],

        if (_activeNav == _FavoritesNav.activities) ...[
          // ── 🧠 Deine Interaktionen ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(label: '🧠  Deine Aktivitäten'),
          ),
          SliverToBoxAdapter(
            child: _InteractionsSection(
              favoriteShowsCount: favState.favoriteShows.length,
              favoriteCreatorsCount: favState.favoriteCreators.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 🎯 Empfehlungen ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(label: '🎯  Für dich empfohlen'),
          ),
          SliverToBoxAdapter(
            child: const _RecommendationsSection(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 🚀 Feature Teaser ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FeatureTeaserSection(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ],
          ),
        ),
      ],
    );
  }
}

class _FavoritesPageSkeleton extends StatelessWidget {
  const _FavoritesPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeletonBox(width: 220, height: 42, borderRadius: BorderRadius.all(Radius.circular(4))),
            SizedBox(height: 24),
            Row(
              children: [
                AppSkeletonBox(width: 92, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                SizedBox(width: 8),
                AppSkeletonBox(width: 92, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                SizedBox(width: 8),
                AppSkeletonBox(width: 72, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
              ],
            ),
            SizedBox(height: 30),
            _FavoritesListSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _FavoritesListSkeleton extends StatelessWidget {
  const _FavoritesListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: List.generate(
          5,
          (_) => Container(
            color: const Color(0xFF1A1A1A),
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: const Row(
              children: [
                AppSkeletonBox(width: 4, height: 40, borderRadius: BorderRadius.zero),
                SizedBox(width: 14),
                Expanded(child: AppSkeletonBox(height: 14)),
                SizedBox(width: 10),
                AppSkeletonCircle(size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _FavoritesNav { favorites, activities, filter }

class _NavChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(31, 255, 255, 255),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isSelected ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
    );
  }
}

class _StreamingFilterSection extends ConsumerWidget {
  final String userId;

  const _StreamingFilterSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServices = ref.watch(streamingServiceFilterProvider);
    final notifier = ref.read(streamingServiceFilterProvider.notifier);
    final isActive = selectedServices.isNotEmpty;

    Future<void> onToggle(String service) async {
      try {
        await notifier.toggle(service);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Streaming-Filter konnte nicht gespeichert werden.'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }

    Future<void> onClear() async {
      try {
        await notifier.clear();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Streaming-Filter konnte nicht zurückgesetzt werden.'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📺  Streaming-Filter',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  GestureDetector(
                    onTap: onClear,
                    child: Text(
                      'Zurücksetzen',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.pop,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Wir zeigen dir nur Inhalte auf deinen Diensten.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAllStreamingServices.map((service) {
                final isSelected = selectedServices.contains(service);
                return GestureDetector(
                  onTap: () => onToggle(service),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.pop.withValues(alpha: 0.12)
                          : const Color(0xFF242424),
                      border: Border.all(
                        color: isSelected ? AppColors.pop : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 20,
                          child: SvgPicture.asset(
                            getStreamingServiceLogo(service),
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.pop,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: AppColors.pop.withValues(alpha: 0.08),
                child: Text(
                  'Filter aktiv: ${selectedServices.join(' & ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.pop,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ─── Section 5: Deine Interaktionen ──────────────────────────────────────────

class _InteractionsSection extends StatelessWidget {
  final int favoriteShowsCount;
  final int favoriteCreatorsCount;

  const _InteractionsSection({
    required this.favoriteShowsCount,
    required this.favoriteCreatorsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          _InteractionRow(
            icon: '❤️',
            label: 'Favoriten (Shows)',
            count: favoriteShowsCount,
            isLive: true,
          ),
          const SizedBox(height: 12),
          _InteractionRow(
            icon: '🎬',
            label: 'Favoriten (Creator)',
            count: favoriteCreatorsCount,
            isLive: true,
          ),
          const SizedBox(height: 12),
          _InteractionRow(
            icon: '🔖',
            label: 'Gemerkt',
            count: 0,
            isLive: false,
          ),
          const SizedBox(height: 12),
          _InteractionRow(
            icon: '▶️',
            label: 'Weitergeschaut',
            count: 0,
            isLive: false,
          ),
        ],
      ),
    );
  }
}

class _InteractionRow extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final bool isLive;

  const _InteractionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isLive ? Colors.white70 : Colors.white24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            color: AppColors.pop,
            child: Text(
              count.toString(),
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E1E1E),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'Kommt bald',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white24,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Section 6: Empfehlungen ──────────────────────────────────────────────────

class _RecommendationsSection extends ConsumerWidget {
  const _RecommendationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteShows =
        ref.watch(favoritesNotifierProvider.select((state) => state.favoriteShows));

    if (favoriteShows.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF1A1A1A),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white24, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Markiere Shows als Favorit, um personalisierte Empfehlungen zu erhalten.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final recommendationsAsync = ref.watch(showRecommendationsProvider);
    final base = favoriteShows.first.displayTitle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context hint
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.pop, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weil du $base magst:',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          recommendationsAsync.when(
            loading: () => const _RecommendationLoadingList(),
            error: (_, __) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Empfehlungen konnten gerade nicht geladen werden.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ),
            data: (recommendations) {
              if (recommendations.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Sobald mehr passende Daten vorhanden sind, erscheinen hier Empfehlungen.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final recommendation in recommendations)
                    _RecoRow(
                      title: recommendation.title,
                      subtitle: recommendation.subtitle,
                      reason: recommendation.reason,
                      onTap: () => context.push(
                        '${AppRoutes.showOverview}/${recommendation.showId}',
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'Basierend auf deinen Favoriten und Nutzern mit aehnlichem Geschmack.',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecoRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String reason;
  final VoidCallback onTap;

  const _RecoRow({
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: const Color(0xFF242424),
        child: Row(
          children: [
            Container(
                width: 3,
                height: 40,
                color: AppColors.pop.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.pop.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _RecommendationLoadingList extends StatelessWidget {
  const _RecommendationLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          color: const Color(0xFF242424),
          child: const Row(
            children: [
              AppSkeletonBox(
                width: 3,
                height: 40,
                borderRadius: BorderRadius.zero,
              ),
              SizedBox(width: 10),
              Expanded(
                child: AppSkeletonLines(
                  lines: 3,
                  height: 8,
                  spacing: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section 12: Feature Teaser ───────────────────────────────────────────────

class _FeatureTeaserSection extends StatelessWidget {
  const _FeatureTeaserSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                color: AppColors.pop,
                child: Text(
                  'DEMNÄCHST',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E1E1E),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '🚀',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Erinnerungen & automatische Highlights',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wir arbeiten daran, dir Erinnerungen zu senden, wenn deine Lieblingsshows neue Episoden haben — und dir automatisch die besten Momente zu zeigen.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white38,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TeaserPill(label: '🔔 Push-Erinnerungen'),
              const SizedBox(width: 8),
              _TeaserPill(label: '✨ Auto-Highlights'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeaserPill extends StatelessWidget {
  final String label;

  const _TeaserPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: Colors.white38,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
