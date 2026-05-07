import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorEventDetailPage extends StatelessWidget {
  final ResolvedCalendarEvent event;
  const CreatorEventDetailPage({super.key, required this.event});
  static const _blue = Color(0xFF4DB6FF);

  String _kindLabel(String? kind) {
    switch (kind) {
      case 'reaction_video': return 'REACTION VIDEO';
      case 'review': return 'REVIEW';
      case 'compilation': return 'COMPILATION';
      case 'interview': return 'INTERVIEW';
      default: return kind?.toUpperCase() ?? 'CREATOR CONTENT';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatted = DateFormat('EEEE, dd. MMMM yyyy \u00b7 HH:mm', 'de_DE')
        .format(event.startDatetime.toLocal());
    final title = event.creatorEventTitle ?? event.creatorName ?? 'Creator Event';
    final description = event.creatorEventDescription;
    final hasYoutubeVideo = event.creatorEventYoutubeUrl != null;
    final hasChannel = event.creatorYoutubeChannelUrl != null;
    final hasInstagram = event.creatorInstagramUrl != null;
    final hasTiktok = event.creatorTiktokUrl != null;
    final hasRelatedShow = event.creatorRelatedShowId != null && event.creatorRelatedShowId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE6FF),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(
              accentColor: _blue,
              badgeLabel: _kindLabel(event.creatorEventKind),
              title: title,
              thumbnailUrl: event.creatorEventThumbnailUrl,
              timeFormatted: timeFormatted,
            ),
            const SizedBox(height: 12),
            if (event.creatorName != null)
              _ContentBlock(
                label: 'CREATOR',
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.creatorDetail, extra: event),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _blue.withOpacity(0.15),
                        backgroundImage: event.creatorAvatarUrl != null
                            ? NetworkImage(event.creatorAvatarUrl!) : null,
                        child: event.creatorAvatarUrl == null
                            ? const Icon(Icons.person, color: _blue, size: 22) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(event.creatorName!,
                            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      if (hasChannel) _SocialIcon(icon: Icons.play_circle_filled_rounded, color: _blue,
                          onTap: () => _launchUrl(event.creatorYoutubeChannelUrl!)),
                      if (hasInstagram) _SocialIcon(icon: Icons.camera_alt_rounded, color: AppColors.pop,
                          onTap: () => _launchUrl(event.creatorInstagramUrl!)),
                      if (hasTiktok) _SocialIcon(icon: Icons.music_note_rounded, color: Colors.white70,
                          onTap: () => _launchUrl(event.creatorTiktokUrl!)),
                      const SizedBox(width: 2),
                      _CreatorFavoriteToggle(event: event),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                    ],
                  ),
                ),
              ),
            if (event.creatorEventEpisodeNumber != null)
              _ContentBlock(
                label: 'EPISODE',
                child: Text('Episode ${event.creatorEventEpisodeNumber}',
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600,
                        color: _blue.withOpacity(0.9))),
              ),
            if (description != null && description.isNotEmpty)
              _ContentBlock(
                label: 'BESCHREIBUNG',
                child: Text(description,
                    style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70, height: 1.6)),
              ),
            if (hasYoutubeVideo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GestureDetector(
                  onTap: () => _launchUrl(event.creatorEventYoutubeUrl!),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: _blue,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                      const SizedBox(width: 8),
                      Text('AUF YOUTUBE ANSEHEN',
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800,
                              color: Colors.black, letterSpacing: 1.0)),
                    ]),
                  ),
                ),
              ),
            if (hasRelatedShow)
              _ContentBlock(
                label: 'ZUGEH\u00d6RIGE SHOW',
                child: GestureDetector(
                  onTap: () => context.push('${AppRoutes.showOverview}/${event.creatorRelatedShowId}'),
                  child: Row(children: [
                    const Icon(Icons.tv_rounded, color: Colors.white38, size: 18),
                    const SizedBox(width: 12),
                    Text('Show anzeigen', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white70)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                  ]),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Color accentColor;
  final String badgeLabel;
  final String title;
  final String? thumbnailUrl;
  final String timeFormatted;

  const _HeroHeader({
    required this.accentColor,
    required this.badgeLabel,
    required this.title,
    required this.timeFormatted,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: accentColor, width: 2)),
      ),
      child: Stack(
        children: [
          if (thumbnailUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.network(thumbnailUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
          ),
          Positioned(
            bottom: 24, left: 20, right: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: accentColor,
                child: Text(badgeLabel,
                    style: GoogleFonts.montserrat(color: Colors.black, fontSize: 11,
                        fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(timeFormatted,
                  style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  final String label;
  final Widget child;
  const _ContentBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: Colors.black,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.only(left: 12),
          child: Icon(icon, color: color, size: 22)),
    );
  }
}

class _CreatorFavoriteToggle extends ConsumerStatefulWidget {
  final ResolvedCalendarEvent event;

  const _CreatorFavoriteToggle({required this.event});

  @override
  ConsumerState<_CreatorFavoriteToggle> createState() =>
      _CreatorFavoriteToggleState();
}

class _CreatorFavoriteToggleState extends ConsumerState<_CreatorFavoriteToggle>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isLoading = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFavorite());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _userId {
    final riverpodUser = ref.read(userNotifierProvider).user;
    return riverpodUser?.id ?? Supabase.instance.client.auth.currentUser?.id;
  }

  Future<String?> _resolveCreatorId() async {
    final directCreatorId = widget.event.creatorId;
    if (directCreatorId != null && directCreatorId.isNotEmpty) {
      return directCreatorId;
    }

    final creatorEventId = widget.event.creatorEventId;
    if (creatorEventId == null || creatorEventId.isEmpty) {
      return null;
    }

    try {
      final row = await Supabase.instance.client
          .from('creator_events')
          .select('creator_id')
          .eq('id', creatorEventId)
          .maybeSingle();
      final creatorId = row?['creator_id'] as String?;
      if (creatorId != null && creatorId.isNotEmpty) {
        return creatorId;
      }
    } catch (_) {
      // Fall through and show missing-id feedback on tap.
    }

    return null;
  }

  Future<void> _checkFavorite() async {
    final creatorId = await _resolveCreatorId();
    final userId = _userId;
    if (creatorId == null || userId == null) return;

    final isFavoriteUseCase = ref.read(isFavoriteCreatorProvider);
    final isFavorite = await isFavoriteUseCase(userId, creatorId);
    if (mounted) setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggle() async {
    final creatorId = await _resolveCreatorId();
    final userId = _userId;

    if (creatorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creator konnte nicht favorisiert werden (ID fehlt).'),
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Melde dich an um Creators zu favorisieren'),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () => context.push(AppRoutes.login),
          ),
        ),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);
    _controller.forward(from: 0);

    final notifier = ref.read(favoritesNotifierProvider.notifier);
    try {
      if (_isFavorite) {
        await notifier.removeCreatorFromFavorites(userId, creatorId);
      } else {
        await notifier.addCreatorToFavorites(
          userId,
          creatorId,
          widget.event.creatorName ?? '',
        );
      }

      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserState>(userNotifierProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        _checkFavorite();
      }
    });

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite
                ? AppColors.pop
                : (_isLoading ? Colors.white38 : Colors.white54),
            size: 22,
          ),
        ),
      ),
    );
  }
}
