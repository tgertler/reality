import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// -----------------------------
/// DATE FORMATTING
/// -----------------------------

String formatFeedDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final date = DateTime.parse(raw).toLocal();
    return DateFormat('dd.MM.yyyy • HH:mm').format(date);
  } catch (_) {
    return raw;
  }
}

String formatFeedDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final date = DateTime.parse(raw).toLocal();
    return DateFormat('dd.MM.yyyy').format(date);
  } catch (_) {
    return raw;
  }
}

/// -----------------------------
/// FEED ITEM PARSER
/// -----------------------------

List<Map<String, dynamic>> parseFeedItems(dynamic rawItems) {
  if (rawItems is String) {
    try {
      final decoded = jsonDecode(rawItems);
      return parseFeedItems(decoded);
    } catch (_) {
      return [];
    }
  }

  if (rawItems is List) {
    return rawItems
        .map((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is Map) return Map<String, dynamic>.from(item);
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (rawItems is Map) {
    final map = rawItems is Map<String, dynamic>
        ? rawItems
        : Map<String, dynamic>.from(rawItems);

    for (final key in const [
      'items',
      'today_events',
      'events',
      'results',
      'data'
    ]) {
      final nested = map[key];
      if (nested is List || nested is Map || nested is String) {
        final parsed = parseFeedItems(nested);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    const indicatorKeys = [
      'show_title',
      'show_short_title',
      'showId',
      'show_id',
      'calendar_event_id',
      'start_datetime',
    ];
    if (indicatorKeys.any(map.containsKey)) {
      return [map];
    }
  }

  return [];
}

String resolvePreferredShowTitle(
  Map<String, dynamic>? data, {
  String fallback = 'Unbekannte Show',
}) {
  if (data == null) return fallback;

  const keys = [
    'show_short_title',
    'short_title',
    'showShortTitle',
    'shortTitle',
    'show_title',
    'showTitle',
    'title',
    'show_name',
    'showName',
  ];

  for (final key in keys) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return fallback;
}

/// -----------------------------
/// BADGE — PREMIUM LOOK
/// -----------------------------

Widget buildFeedBadge(
  String label, {
  Color color = Colors.white24,
  double fontSize = 13,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  double radius = 4,
  Color? textColor,
}) {
  final effectiveTextColor = textColor ??
      (color.computeLuminance() > 0.5 ? Colors.black : Colors.white);

  return Transform.rotate(
    angle: -0.018,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Color.fromRGBO(
            color.r.round(), color.g.round(), color.b.round(), 0.92),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: effectiveTextColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    ),
  );
}

/// -----------------------------
/// SECTION DIVIDER — APPLE TV STYLE
/// -----------------------------

Widget buildSectionDivider({
  double spacing = 24,
  double thickness = 1.0,
  Color color = Colors.white24,
  IconData icon = Icons.auto_awesome,
  double iconSize = 16,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: spacing),
    child: Row(
      children: [
        Expanded(
          child: Container(height: thickness, color: color),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: thickness, color: color),
        ),
      ],
    ),
  );
}

/// -----------------------------
/// TIMELINE ENTRY — PREMIUM VERSION
/// -----------------------------

Widget buildTimelineEntry(
  String title,
  String subtitle, {
  Color accent = Colors.white38,
  double iconSize = 14,
  TextStyle? titleStyle,
  TextStyle? subtitleStyle,
  double spacing = 16,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: spacing / 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DOT
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: titleStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: subtitleStyle ??
                    const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// -----------------------------
/// ROCKET BUBBLE — EXCITEMENT INDICATOR
/// -----------------------------

class RocketBubble extends StatefulWidget {
  final VoidCallback? onTap;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const RocketBubble({
    super.key,
    this.onTap,
    this.size = 32,
    this.backgroundColor = AppColors.pop,
    this.iconColor = Colors.white,
  });

  @override
  State<RocketBubble> createState() => _RocketBubbleState();
}

class _RocketBubbleState extends State<RocketBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLaunched = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isLaunched) return;

    setState(() => _isLaunched = true);
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.reverse();
        }
      });
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isLaunched ? Icons.check : Icons.rocket_launch_rounded,
                size: widget.size * 0.6,
                color: widget.iconColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// -----------------------------
/// FLAT EVENT ROW
/// -----------------------------

String _normalizeEventType(String rawType) {
  final normalized = rawType.trim().toLowerCase();
  if (normalized.isEmpty) return '';

  switch (normalized) {
    case 'premiere':
      return 'Premiere';
    case 'finale':
      return 'Finale';
    case 'reunion':
      return 'Reunion';
    case 'release':
      return 'Release';
    case 'regular':
      return 'Standard';
    default:
      return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

String? _buildEventRowSubtitle(String? subtitle, Map<String, dynamic>? entry) {
  final seasonLabel = _buildSeasonLabel(entry);
  if ((subtitle == null || subtitle.isEmpty) && seasonLabel.isEmpty) {
    return null;
  }

  if (subtitle == null || subtitle.isEmpty) {
    return seasonLabel;
  }

  if (seasonLabel.isEmpty) {
    return subtitle;
  }

  return '$seasonLabel • $subtitle';
}

String _buildSeasonLabel(Map<String, dynamic>? entry) {
  if (entry == null) return '';

  final rawSeason =
      entry['season_number'] ?? entry['season'] ?? entry['seasonNumber'];
  if (rawSeason == null) return '';

  final seasonValue = rawSeason.toString().trim();
  if (seasonValue.isEmpty) return '';

  final seasonNumber = int.tryParse(seasonValue);
  if (seasonNumber != null && seasonNumber > 0) {
    return 'S$seasonNumber';
  }

  if (seasonValue.toLowerCase().startsWith('s')) {
    return seasonValue.toUpperCase();
  }

  return 'S$seasonValue';
}

Widget _buildEventTypeBadge(String typeLabel) {
  final color = _eventTypeColor(typeLabel);
  final red = (color.r * 255.0).round().clamp(0, 255);
  final green = (color.g * 255.0).round().clamp(0, 255);
  final blue = (color.b * 255.0).round().clamp(0, 255);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Color.fromRGBO(red, green, blue, 1),
      borderRadius: BorderRadius.circular(3),
      // border: Border.all(
      //   color: Color.fromRGBO(red, green, blue, 0.35),
      //   width: 1.0,
      // ),
    ),
    child: Text(
      typeLabel.toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    ),
  );
}

Color _eventTypeColor(String typeLabel) {
  switch (typeLabel.toLowerCase()) {
    case 'premiere':
      return const Color.fromARGB(255, 11, 162, 212);
    case 'finale':
      return const Color.fromARGB(255, 223, 50, 50);
    case 'reunion':
      return const Color(0xFFFFD166);
    case 'release':
      return const Color.fromARGB(255, 47, 196, 109);
    case 'standard':
      return const Color.fromARGB(255, 55, 55, 55);
    default:
      return const Color(0xFFBDBDBD);
  }
}

Widget buildFlatEventRow({
  required BuildContext context,
  required String title,
  String? subtitle,
  Widget? trailing,
  Map<String, dynamic>? entry,
  IconData? icon,
  Color accentColor = const Color(0xFF00B4FF),
  Color iconBackground = const Color(0xFF00B4FF),
  Color iconColor = Colors.white,
  Color background = const Color(0xFF1E1E1E),
  double radius = 4,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  EdgeInsets margin = const EdgeInsets.only(bottom: 14),
  TextStyle? titleStyle,
  TextStyle? subtitleStyle,
  bool showRocket = false,
  VoidCallback? onRocketTap,
  bool showEventType = true,
}) {
  final effectiveSubtitle = _buildEventRowSubtitle(subtitle, entry);
  final typeLabel = showEventType && entry != null && entry != 'regular'
      ? _normalizeEventType(entry['event_type']?.toString() ?? '')
      : '';
  final typeBadge =
      typeLabel.isNotEmpty ? _buildEventTypeBadge(typeLabel) : null;

  // Build streaming logo if entry has streaming_option
  Widget? streamingLogo;
  if (entry != null) {
    final streamingService = entry['streaming_option']?.toString() ?? '';
    if (streamingService.isNotEmpty) {
      streamingLogo = SizedBox(
        height: 25,
        width: 70,
        child: SvgPicture.asset(
          getStreamingServiceLogo(streamingService),
          height: 22,
          width: 22,
          fit: BoxFit.contain,
        ),
      );
    }
  }

  // Combine trailing with streaming logo
  Widget? effectiveTrailing;
  if (streamingLogo != null && trailing != null) {
    effectiveTrailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        streamingLogo,
        const SizedBox(width: 8),
        trailing,
      ],
    );
  } else if (streamingLogo != null) {
    effectiveTrailing = streamingLogo;
  } else {
    effectiveTrailing = trailing;
  }

  VoidCallback? onTap;
  if (entry != null) {
    final targetId = entry['show_id']?.toString() ?? entry['id']?.toString();
    if (targetId != null && targetId.isNotEmpty) {
      onTap = () => context.push('${AppRoutes.showOverview}/$targetId');
    }
  }

  final row = Container(
    margin: margin,
    constraints: const BoxConstraints(minHeight: 68),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      border: Border(
        left: BorderSide(
          color: accentColor.withValues(alpha: 0.38),
          width: 2,
        ),
      ),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // if (icon != null) ...[
              //   Container(
              //     width: 42,
              //     height: 42,
              //     decoration: BoxDecoration(
              //       color: iconBackground,
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Icon(icon, color: iconColor, size: 22),
              //   ),
              //   const SizedBox(width: 14),
              // ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (effectiveSubtitle != null &&
                        effectiveSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (typeBadge != null) ...[
                            typeBadge,
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              effectiveSubtitle,
                              style: subtitleStyle ??
                                  const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else if (typeBadge != null) ...[
                      const SizedBox(height: 6),
                      typeBadge,
                    ],
                  ],
                ),
              ),
              if (effectiveTrailing != null) ...[
                const SizedBox(width: 12),
                effectiveTrailing,
              ],
            ],
          ),
        ),
        if (showRocket)
          Positioned(
            top: -8,
            right: -8,
            child: RocketBubble(
              onTap: onRocketTap,
              backgroundColor: accentColor,
            ),
          ),
      ],
    ),
  );

  if (onTap != null) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: row,
      ),
    );
  }

  return row;
}

/// -----------------------------
/// HERO EMOJI — BIG HEADER ELEMENT
/// -----------------------------

Widget buildHeroEmoji(String emoji, {double size = 56}) {
  return Text(
    String.fromCharCode(emoji.runes.first), // WICHTIG!
    style: TextStyle(
      fontSize: size,
      height: 1,
      fontFamily: "NotoColorEmoji", // optionaler Fix für Android
    ),
  );
}

/// -----------------------------
/// CARD BACKGROUND HELPERS
/// -----------------------------

BoxDecoration buildCardBackground({
  List<Color> colors = const [
    Color(0xFF1C2A35),
    Color(0xFF0B1A21),
  ],
  double radius = 32,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      const BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.45),
        blurRadius: 20,
        offset: Offset(0, 10),
      )
    ],
  );
}
