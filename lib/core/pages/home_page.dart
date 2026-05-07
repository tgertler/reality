import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/favorites_home_section_widget.dart';
import 'package:frontend/core/widgets/home_streaming_content_widget.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:once/once.dart';

import '../widgets/top_bar_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showFeaturesPromo = true;
  bool _showBingoPromo = true;
  final ScrollController _homeScrollController = ScrollController();
  bool _showTopScrollHint = false;
  bool _showBottomScrollHint = false;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_updateScrollHints);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).loadUserData();
      _updateScrollHints();
    });
  }

  @override
  void dispose() {
    _homeScrollController
      ..removeListener(_updateScrollHints)
      ..dispose();
    super.dispose();
  }

  void _scheduleScrollHintUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateScrollHints();
    });
  }

  void _updateScrollHints() {
    if (!_homeScrollController.hasClients) {
      if (_showTopScrollHint || _showBottomScrollHint) {
        setState(() {
          _showTopScrollHint = false;
          _showBottomScrollHint = false;
        });
      }
      return;
    }

    final position = _homeScrollController.position;
    const epsilon = 1.0;
    final nextTop = position.pixels > epsilon;
    final nextBottom = position.maxScrollExtent - position.pixels > epsilon;

    if (nextTop != _showTopScrollHint || nextBottom != _showBottomScrollHint) {
      setState(() {
        _showTopScrollHint = nextTop;
        _showBottomScrollHint = nextBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userNotifierProvider);
    _scheduleScrollHintUpdate();
    return Scaffold(
      appBar: TopBarWidget(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 247, 227, 255),
              Color.fromARGB(255, 243, 216, 255),
            ],
          ),
        ),
        child: Container(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _homeScrollController,
                      child: Column(
                        children: [
                          /* if (userState.user != null)  */ //const WelcomeMessageWidget(),
                          //if (userState.user == null) const NotLoggedInMessageWidget(),
                          // OnceWidget.showHourly(
                          //   "weekWidget",
                          //   builder: () {
                          //     return TrashCalendarWidget(
                          //       onClose: () {},
                          //     );
                          //   },
                          //   fallback: () => Container(),
                          // ),
                          // OnceWidget.showHourly(
                          //   'featuresPromoWidget',
                          //   builder: () {
                          //     if (!_showFeaturesPromo) return Container();
                          //     return _FeaturesPromoHomeCard(
                          //       onDismiss: () {
                          //         if (!mounted) return;
                          //         setState(() => _showFeaturesPromo = false);
                          //       },
                          //     );
                          //   },
                          //   fallback: () => Container(),
                          // ),
                          // OnceWidget.showHourly(
                          //   'bingoPromoWidget',
                          //   builder: () {
                          //     if (!_showBingoPromo) return Container();
                          //     return _BingoPromoHomeCard(
                          //       onDismiss: () {
                          //         if (!mounted) return;
                          //         setState(() => _showBingoPromo = false);
                          //       },
                          //     );
                          //   },
                          //   fallback: () => Container(),
                          // ),
                          const FavoritesHomeSectionWidget(),
                          HomeStreamingContentWidget()
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _showTopScrollHint ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 20,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x26000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _showBottomScrollHint ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 24,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x00000000),
                                  Color(0x4D000000),
                                ],
                              ),
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
        ),
      ),
    );
  }
}

class _BingoPromoHomeCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _BingoPromoHomeCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Dismissible(
        key: const ValueKey('bingo-promo-message'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onDismiss(),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 48, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF7D7),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(4, 4),
                    blurRadius: 0,
                    color: Colors.black,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.pop,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Text(
                          'WATCHPARTY',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.pop,
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bingo macht jede Folge zur kleinen Watchparty',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Starte live zur Episode dein Bingo, hake typische Momente ab und öffne alte Runden später wieder.',
                              style: GoogleFonts.dmSans(
                                color: Colors.black87,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                side: const BorderSide(color: Colors.black, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => context.go(AppRoutes.calendar),
                              child: const Text('Zur Watchparty im Kalender'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onDismiss,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black.withValues(alpha: 0.45),
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

class _FeaturesPromoHomeCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _FeaturesPromoHomeCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Dismissible(
        key: const ValueKey('features-promo-message'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onDismiss(),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 48, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFAFF),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(4, 4),
                    blurRadius: 0,
                    color: Colors.black,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE600),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            'NEU',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ERINNERUNGEN + FILTER',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Aktiviere Erinnerungen und filtere Inhalte nach deinen Streaming-Diensten in Mein Bereich.',
                          style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: const BorderSide(color: Colors.black, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => context.go(AppRoutes.user),
                          child: const Text('Zu Mein Bereich'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onDismiss,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black.withValues(alpha: 0.45),
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
