import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorDetailPage extends ConsumerStatefulWidget {
  final ResolvedCalendarEvent event;
  const CreatorDetailPage({super.key, required this.event});

  @override
  ConsumerState<CreatorDetailPage> createState() => _CreatorDetailPageState();
}

class _CreatorDetailPageState extends ConsumerState<CreatorDetailPage>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF4DB6FF);

  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isLoadingCreatorData = false;
  Map<String, dynamic>? _creatorProfile;
  List<Map<String, dynamic>> _creatorEvents = const [];
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFavorite());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCreatorData());
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
      final response = await Supabase.instance.client
          .from('creator_events')
          .select('creator_id')
          .eq('id', creatorEventId)
          .maybeSingle();

      final resolved = response?['creator_id'] as String?;
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    } catch (_) {
      // If lookup fails we keep the current behavior and show a clear message.
    }

    return null;
  }

  Future<void> _checkFavorite() async {
    final creatorId = await _resolveCreatorId();
    final userId = _userId;
    if (creatorId == null || userId == null) return;
    final isFavoriteUseCase = ref.read(isFavoriteCreatorProvider);
    final result = await isFavoriteUseCase(userId, creatorId);
    if (mounted) setState(() => _isFavorite = result);
  }

  Future<void> _loadCreatorData() async {
    final creatorId = await _resolveCreatorId();
    if (creatorId == null || !mounted) return;

    setState(() => _isLoadingCreatorData = true);

    try {
      final creatorsClient = Supabase.instance.client;

      final profile = await creatorsClient
          .from('creators')
          .select(
              'id, name, avatar_url, youtube_channel_url, instagram_url, tiktok_url')
          .eq('id', creatorId)
          .maybeSingle();

      final eventsRaw = await creatorsClient
          .from('creator_events')
          .select(
              'id, title, event_kind, episode_number, description, youtube_url, thumbnail_url, related_show_id, related_season_id, created_at')
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false)
          .limit(20);

      final events = (eventsRaw as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final showIds = events
          .map((e) => e['related_show_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final seasonIds = events
          .map((e) => e['related_season_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, String> showTitles = {};
      final Map<String, int> seasonNumbers = {};

      if (showIds.isNotEmpty) {
        final showsRaw = await creatorsClient
            .from('shows')
            .select('id, title, short_title')
            .inFilter('id', showIds);
        for (final row in (showsRaw as List<dynamic>).cast<Map<String, dynamic>>()) {
          final id = row['id']?.toString();
          if (id == null) continue;
          final short = row['short_title']?.toString().trim();
          final title = row['title']?.toString().trim();
          showTitles[id] = (short != null && short.isNotEmpty)
              ? short
              : (title == null || title.isEmpty ? 'Show' : title);
        }
      }

      if (seasonIds.isNotEmpty) {
        final seasonsRaw = await creatorsClient
            .from('seasons')
            .select('id, season_number')
            .inFilter('id', seasonIds);
        for (final row in (seasonsRaw as List<dynamic>).cast<Map<String, dynamic>>()) {
          final id = row['id']?.toString();
          final number = row['season_number'] as int?;
          if (id != null && number != null) {
            seasonNumbers[id] = number;
          }
        }
      }

      final enriched = events.map((e) {
        final showId = e['related_show_id']?.toString();
        final seasonId = e['related_season_id']?.toString();
        return {
          ...e,
          'show_title': showId == null ? null : showTitles[showId],
          'season_number': seasonId == null ? null : seasonNumbers[seasonId],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _creatorProfile = profile;
        _creatorEvents = enriched;
        _isLoadingCreatorData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCreatorData = false);
    }
  }

  Future<void> _toggle() async {
    final creatorId = await _resolveCreatorId();
    final userId = _userId;
    if (creatorId == null || creatorId.isEmpty) {
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
            userId, creatorId, widget.event.creatorName ?? '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '"${widget.event.creatorName ?? 'Creator'}" zu Favoriten hinzugefügt'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final name = (_creatorProfile?['name'] as String?) ?? event.creatorName ?? 'Creator';
    final youtube = (_creatorProfile?['youtube_channel_url'] as String?) ??
      event.creatorYoutubeChannelUrl;
    final instagram = (_creatorProfile?['instagram_url'] as String?) ??
      event.creatorInstagramUrl;
    final tiktok = (_creatorProfile?['tiktok_url'] as String?) ??
      event.creatorTiktokUrl;
    final avatarUrl = (_creatorProfile?['avatar_url'] as String?) ??
      event.creatorAvatarUrl;
    final hasYoutube = youtube != null && youtube.isNotEmpty;
    final hasInstagram = instagram != null && instagram.isNotEmpty;
    final hasTiktok = tiktok != null && tiktok.isNotEmpty;
    final hasRelatedShow = event.creatorRelatedShowId != null &&
        event.creatorRelatedShowId!.isNotEmpty;
    final hasCreatorId = event.creatorId?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE6FF),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Hero Header ────────────────────────────────────────────────
            _CreatorHeroHeader(
              accentColor: _blue,
              name: name,
              avatarUrl: avatarUrl,
              isFavorite: _isFavorite,
              isLoading: _isLoading,
              hasCreatorId: hasCreatorId,
              scaleAnimation: _scaleAnimation,
              onFavoriteTap: _toggle,
            ),
            const SizedBox(height: 12),

            // ── Social Channels ────────────────────────────────────────────
            if (hasYoutube || hasInstagram || hasTiktok)
              _ContentBlock(
                label: 'KANÄLE',
                child: Row(
                  children: [
                    if (hasYoutube)
                      _ChannelButton(
                        icon: Icons.play_circle_filled_rounded,
                        label: 'YouTube',
                        color: _blue,
                        onTap: () => _launchUrl(youtube),
                      ),
                    if (hasInstagram)
                      _ChannelButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Instagram',
                        color: AppColors.pop,
                        onTap: () => _launchUrl(instagram),
                      ),
                    if (hasTiktok)
                      _ChannelButton(
                        icon: Icons.music_note_rounded,
                        label: 'TikTok',
                        color: Colors.white70,
                        onTap: () => _launchUrl(tiktok),
                      ),
                  ],
                ),
              ),

            // ── Creator Events ───────────────────────────────────────────
            _ContentBlock(
              label: 'CREATOR EVENTS',
              child: _isLoadingCreatorData
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _creatorEvents.isEmpty
                      ? Text(
                          'Noch keine Creator-Events gefunden.',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: Colors.white54),
                        )
                      : Column(
                          children: _creatorEvents
                              .map((creatorEvent) => _CreatorEventListTile(
                                    event: creatorEvent,
                                    accentColor: _blue,
                                    onOpenUrl: _launchUrl,
                                    onOpenShow: (showId) => context.push(
                                      '${AppRoutes.showOverview}/$showId',
                                    ),
                                  ))
                              .toList(),
                        ),
            ),

            // ── Related Show ───────────────────────────────────────────────
            if (hasRelatedShow)
              _ContentBlock(
                label: 'ZUGEHÖRIGE SHOW',
                child: GestureDetector(
                  onTap: () => context.push(
                      '${AppRoutes.showOverview}/${event.creatorRelatedShowId}'),
                  child: Row(children: [
                    const Icon(Icons.tv_rounded,
                        color: Colors.white38, size: 18),
                    const SizedBox(width: 12),
                    Text('Show anzeigen',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: Colors.white70)),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: Colors.white38, size: 18),
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

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _CreatorHeroHeader extends StatelessWidget {
  final Color accentColor;
  final String name;
  final String? avatarUrl;
  final bool isFavorite;
  final bool isLoading;
  final bool hasCreatorId;
  final Animation<double> scaleAnimation;
  final VoidCallback onFavoriteTap;

  const _CreatorHeroHeader({
    required this.accentColor,
    required this.name,
    required this.isFavorite,
    required this.isLoading,
    required this.hasCreatorId,
    required this.scaleAnimation,
    required this.onFavoriteTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: accentColor, width: 2)),
      ),
      child: Stack(
        children: [
          // Back arrow
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
          ),
          // Favorite button
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: AnimatedBuilder(
              animation: scaleAnimation,
              builder: (_, child) => Transform.scale(
                scale: scaleAnimation.value,
                child: child,
              ),
              child: IconButton(
                onPressed: isLoading ? null : onFavoriteTap,
                tooltip:
                    hasCreatorId ? 'Creator favorisieren' : 'Creator ID fehlt',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.redAccent
                      : (hasCreatorId ? Colors.white54 : Colors.white30),
                  size: 26,
                ),
              ),
            ),
          ),
          // Creator info
          Positioned(
            bottom: 28,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: accentColor.withOpacity(0.18),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person,
                          color: accentColor, size: 38)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        color: accentColor,
                        child: Text(
                          'CREATOR',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ChannelButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: color.withOpacity(0.12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CreatorEventListTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final Color accentColor;
  final Future<void> Function(String url) onOpenUrl;
  final void Function(String showId) onOpenShow;

  const _CreatorEventListTile({
    required this.event,
    required this.accentColor,
    required this.onOpenUrl,
    required this.onOpenShow,
  });

  @override
  Widget build(BuildContext context) {
    final title = (event['title']?.toString().trim().isNotEmpty == true)
        ? event['title'].toString().trim()
        : (event['event_kind']?.toString().toUpperCase() ?? 'CREATOR EVENT');
    final showTitle = event['show_title']?.toString();
    final seasonNumber = event['season_number']?.toString();
    final episodeNumber = event['episode_number']?.toString();
    final youtubeUrl = event['youtube_url']?.toString();
    final showId = event['related_show_id']?.toString();

    final infoParts = <String>[];
    if (showTitle != null && showTitle.isNotEmpty) infoParts.add(showTitle);
    if (seasonNumber != null && seasonNumber.isNotEmpty) {
      infoParts.add('S$seasonNumber');
    }
    if (episodeNumber != null && episodeNumber.isNotEmpty) {
      infoParts.add('E$episodeNumber');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF141414),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: Container(
          width: 3,
          color: accentColor,
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: infoParts.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  infoParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showId != null && showId.isNotEmpty)
              IconButton(
                tooltip: 'Show',
                icon: const Icon(Icons.tv, color: Colors.white54, size: 18),
                onPressed: () => onOpenShow(showId),
              ),
            if (youtubeUrl != null && youtubeUrl.isNotEmpty)
              IconButton(
                tooltip: 'YouTube',
                icon: Icon(Icons.play_circle_fill, color: accentColor, size: 20),
                onPressed: () => onOpenUrl(youtubeUrl),
              ),
          ],
        ),
      ),
    );
  }
}
