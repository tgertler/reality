import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_tiktok_tag_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';

class RandomShowFeedCard extends StatefulWidget {
  final FeedItem item;

  const RandomShowFeedCard({super.key, required this.item});

  @override
  State<RandomShowFeedCard> createState() => _RandomShowFeedCardState();
}

class _RandomShowFeedCardState extends State<RandomShowFeedCard>
    with TickerProviderStateMixin {
  late List<String> _showTitles;
  late List<String> _showIds;
  late int _currentIndex;
  String _currentShowId = '';

  // Controllers
  late AnimationController _wheelCtrl;  // wheel rotation
  late AnimationController _pulseCtrl;  // pre-spin pulse
  late AnimationController _revealCtrl; // reveal fade+scale

  late Animation<double> _wheelRotation;
  late Animation<double> _pulseScale;
  late Animation<double> _revealOpacity;
  late Animation<double> _revealScale;

  bool _isSpinning = false;
  bool _hasRevealed = false;

  @override
  void initState() {
    super.initState();
    _showTitles = _parseShowTitles();
    _showIds = _parseShowIds();
    _currentIndex = 0;
    _currentShowId = _showIds.isNotEmpty ? _showIds[0] : '';

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _wheelRotation = Tween<double>(begin: 0, end: 6 * pi).animate(
      CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOut),
    );

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeIn),
    );
    _revealScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.elasticOut),
    );

    // Auto-spin on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _spin());
  }

  List<String> _parseShowTitles() {
    final items = parseFeedItems(widget.item.data['items']);
    if (items.isNotEmpty) {
      return items
          .map((e) => resolvePreferredShowTitle(e, fallback: ''))
          .where((t) => t.isNotEmpty)
          .toList();
    }
    final single = resolvePreferredShowTitle(widget.item.data, fallback: '');
    if (single.isNotEmpty) return [single];
    return ['Love Island', 'The Traitors', 'GNTM', 'Elite House'];
  }

  List<String> _parseShowIds() {
    final items = parseFeedItems(widget.item.data['items']);
    if (items.isNotEmpty) {
      return items
          .map((e) => e['show_id']?.toString() ?? '')
          .toList();
    }
    final single = widget.item.data['show_id']?.toString();
    return [single ?? ''];
  }

  Future<void> _spin() async {
    if (_isSpinning || _showTitles.isEmpty) return;
    setState(() {
      _isSpinning = true;
      _hasRevealed = false;
    });

    // Phase 1: pulse
    await _pulseCtrl.forward();
    await _pulseCtrl.reverse();

    // Pick random show before spin completes
    final next = Random().nextInt(_showTitles.length);

    // Phase 2: spin
    _wheelCtrl.reset();
    await _wheelCtrl.forward();

    setState(() {
      _currentIndex = next;
      _currentShowId = _showIds.length > next ? _showIds[next] : '';
      _isSpinning = false;
      _hasRevealed = true;
    });

    // Phase 3: reveal
    _revealCtrl.reset();
    _revealCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _wheelCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle =
        _showTitles.isNotEmpty ? _showTitles[_currentIndex] : '—';

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Column(
                children: [
                  Text(
                    'RANDOM',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 42,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    'SHOW',
                    style: GoogleFonts.montserrat(
                      color: AppColors.pop,
                      fontSize: 42,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: AnimatedBuilder(
                    animation: _wheelRotation,
                    builder: (_, __) => Transform.rotate(
                      angle: _wheelRotation.value,
                      child: _WheelWidget(isSpinning: _isSpinning),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_hasRevealed)
                FadeTransition(
                  opacity: _revealOpacity,
                  child: ScaleTransition(
                    scale: _revealScale,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F1F1),
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deine Show:',
                            style: GoogleFonts.montserrat(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_currentShowId.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            FeedCardTikTokTag(
                              showId: _currentShowId,
                              suffix: ' findet diese Show spannend',
                              isDark: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.black26,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _isSpinning ? 'Dreht ...' : 'Ziehe eine Show',
                    style: GoogleFonts.montserrat(
                      color: Colors.black54,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasRevealed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.pop,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Anschauen',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wheel widget ─────────────────────────────────────────────────────────────

class _WheelWidget extends StatelessWidget {
  final bool isSpinning;

  const _WheelWidget({required this.isSpinning});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(180, 180),
      painter: _WheelPainter(isSpinning: isSpinning),
      child: SizedBox(
        width: 180,
        height: 180,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pop,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            // child: Center(
            //   child: Text(
            //     isSpinning ? '🎡' : '🎯',
            //     style: const TextStyle(fontSize: 18),
            //   ),
            // ),
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final bool isSpinning;

  static const _segmentColors = [
    AppColors.pop,
    Color.fromARGB(59, 108, 23, 114),
    Color.fromARGB(164, 248, 144, 255),
    AppColors.pop,
    Color.fromARGB(181, 177, 40, 187),
    Color.fromARGB(237, 245, 189, 249),
  ];

  const _WheelPainter({required this.isSpinning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sweepAngle = 2 * pi / 6;

    for (int i = 0; i < 6; i++) {
      final paint = Paint()
        ..color = _segmentColors[i % _segmentColors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle - pi / 2,
        sweepAngle,
        true,
        paint,
      );
    }

    // Divider lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 6; i++) {
      final angle = i * sweepAngle - pi / 2;
      canvas.drawLine(
        center,
        center + Offset(cos(angle) * radius, sin(angle) * radius),
        linePaint,
      );
    }

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Glow ring when spinning
    if (isSpinning) {
      canvas.drawCircle(
        center,
        radius + 5,
        Paint()
          ..color = const Color.fromARGB(255, 248, 144, 255).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.isSpinning != isSpinning;
}
