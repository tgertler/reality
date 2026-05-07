import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/creator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainSearchCreatorCard extends ConsumerWidget {
  final Creator creator;

  const MainSearchCreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        context.push(
          AppRoutes.creatorDetail,
          extra: ResolvedCalendarEvent(
            calendarEventId: 'search_creator_${creator.id}',
            startDatetime: now,
            endDatetime: now,
            isShowEvent: false,
            isCreatorEvent: true,
            isTrashEvent: false,
            creatorId: creator.id,
            creatorName: creator.name,
            creatorAvatarUrl: creator.avatarUrl,
            creatorYoutubeChannelUrl: creator.youtubeChannelUrl,
            creatorInstagramUrl: creator.instagramUrl,
            creatorTiktokUrl: creator.tiktokUrl,
            creatorEventDescription: creator.description,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
        child: Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4DB6FF).withValues(alpha: 0.2),
                backgroundImage: creator.avatarUrl != null
                    ? NetworkImage(creator.avatarUrl!)
                    : null,
                child: creator.avatarUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF4DB6FF), size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Creator',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF4DB6FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}