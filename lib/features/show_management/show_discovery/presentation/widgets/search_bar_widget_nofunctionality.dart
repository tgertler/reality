import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/router.dart';

class MainSearchBarWidgetNofunctionality extends ConsumerWidget {
  const MainSearchBarWidgetNofunctionality({super.key});

  void _openUpcomingFeaturesOverlay(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.rocket_launch, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kommende Features',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: Column(
                      children: [
                        _RoadmapBlock(
                          icon: Icons.auto_awesome,
                          title: 'Mehr Personalisierung',
                          summary: 'Relevanter, schneller, persönlicher.',
                          bullets: const [
                            'Push-Nachrichten zu Favoriten und Premieren',
                            'Persönliche Empfehlungen und smarter Feed',
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RoadmapBlock(
                          icon: Icons.groups_2,
                          title: 'Teilnehmer & Beziehungen',
                          summary: 'Mehr Kontext zu Rollen und Dynamiken.',
                          bullets: const [
                            'Allianzen, Konflikte und Historie sichtbar machen',
                            'Teilnehmer mit Staffeln und Episoden verknüpfen',
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var textFieldController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
      ),
      margin: EdgeInsets.zero, // Entfernt jeglichen Rand
      padding: EdgeInsets.zero, // Entfernt jegliches Padding
      child: TextField(
        readOnly: true,
        controller: textFieldController,
        onTap: () => {
          /* ref.read(mainSearchOverlayProvider.notifier).showOverlay(), */
          context.push(AppRoutes.mainSearch),
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
          ),
          hintText: 'Suchen',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: IconButton(
                  iconSize: 24,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  color: const Color.fromARGB(155, 255, 255, 255),
                  onPressed: () => _openUpcomingFeaturesOverlay(context),
                  tooltip: 'Kommende Features',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 0),
                child: SizedBox(
                  height: 30.0,
                  width: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: IconButton(
                  iconSize: 28,
                  icon: Icon(Icons.account_circle),
                  color: Colors.white,
                  onPressed: () {
                    // Hier kannst du die Navigation oder andere Aktionen hinzufügen
                    context.push(AppRoutes.user);
                  },
                ),
              ),
            ],
          ),
          fillColor: const Color(0xFF121212),
          filled: true,
          //contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

class _RoadmapBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final List<String> bullets;

  const _RoadmapBlock({
    required this.icon,
    required this.title,
    required this.summary,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.brightness_1, size: 6, color: Colors.white38),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
