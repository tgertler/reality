import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/seasons_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'season_list_item_widget.dart';

class SeasonListWidget extends ConsumerStatefulWidget {
  final String showId;
  final Color accentColor;

  const SeasonListWidget({
    super.key,
    required this.showId,
    this.accentColor = AppColors.pop,
  });

  @override
  _SeasonListWidgetState createState() => _SeasonListWidgetState();
}

class _SeasonListWidgetState extends ConsumerState<SeasonListWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(seasonsNotifierProvider.notifier)
          .getSeasonsByShow(widget.showId);
    });
  }

  @override
  void didUpdateWidget(covariant SeasonListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      setState(() => _isExpanded = false);
      ref
          .read(seasonsNotifierProvider.notifier)
          .getSeasonsByShow(widget.showId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonState = ref.watch(seasonsNotifierProvider);
    final seasons = [...seasonState.seasons]
      ..sort((a, b) => b.seasonNumber.compareTo(a.seasonNumber));

    if (seasonState.isLoading && seasons.isEmpty) {
      return const _SeasonListSkeleton();
    }

    if (seasons.isEmpty && !seasonState.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          //borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(
              color: Colors.white.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            //borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.movie_filter_rounded,
                            color: Colors.black,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Staffeln',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Alle Staffeln im Überblick',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${seasons.length}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      if (seasonState.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  seasonState.errorMessage,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: seasons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final season = seasons[index];
                            return SeasonListItemWidget(
                              season: season,
                              accentColor: widget.accentColor,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonListSkeleton extends StatelessWidget {
  const _SeasonListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          children: [
            const Row(
              children: [
                AppSkeletonBox(
                    width: 30,
                    height: 30,
                    borderRadius: BorderRadius.all(Radius.circular(6))),
                SizedBox(width: 12),
                AppSkeletonBox(width: 92, height: 16),
                SizedBox(width: 8),
                AppSkeletonBox(width: 28, height: 18),
                Spacer(),
                AppSkeletonBox(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: AppSkeletonBox(
                    height: 54,
                    borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
