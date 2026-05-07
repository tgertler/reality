import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/bottom_bar_widget.dart';
import 'package:frontend/features/calendar_management/presentation/pages/calendar_page.dart';
import 'package:frontend/features/content_management/presentation/pages/content_management_page.dart';
import 'package:frontend/features/favorites_management/presentation/pages/favorites_page.dart';
import 'package:frontend/features/bingo_management/presentation/pages/show_event_bingo_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/attendee_overview_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/creator_detail_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/creator_event_detail_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/search_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/season_overview_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/trash_event_detail_page.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/user_management/presentation/pages/login_page.dart';
import 'package:frontend/features/user_management/presentation/pages/register_page.dart';
import 'package:frontend/features/user_management/presentation/pages/user_page.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/feed_management/presentation/pages/feed_page.dart';
import '../../features/show_management/show_discovery/presentation/pages/show_overview_page.dart';
import '../pages/home_page.dart';

final _routerKey = GlobalKey<NavigatorState>();
GlobalKey<NavigatorState> get appNavigatorKey => _routerKey;

bool _currentUserIsEditor() {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  final metadata = user.appMetadata;
  final role = metadata['role']?.toString().toLowerCase();
  final rolesRaw = metadata['roles'];
  final roles = rolesRaw is List
      ? rolesRaw.map((e) => e.toString().toLowerCase()).toList()
      : const <String>[];
  return role == 'editor' || roles.contains('editor');
}

class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String feed = '/feed';
  static const String calendar = '/calendar';
  static const String showOverview = '/show_overview';
  static const String seasonOverview = '/season_overview';
  static const String mainSearch = '/main_search';
  static const String calendarFilter = '/filter';
  static const String login = '/login';
  static const String register = '/register';
  static const String user = '/user';
  static const String favorites = '/favorites';
  static const String contentManagement = '/content-management';
  static const String attendeeOverview = '/attendee_overview';
  static const String creatorDetail = '/creator_detail';
  static const String creatorEventDetail = '/creator_event_detail';
  static const String trashEventDetail = '/trash_event_detail';
  static const String showEventDetail = '/show_event_detail';
}

final router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: AppRoutes.feed,
/*   redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoggingIn = state.uri.toString() == AppRoutes.login ||
        state.uri.toString() == AppRoutes.register;

    if (!isLoggedIn && !isLoggingIn) {
      return AppRoutes.login;
    }
    if (isLoggedIn &&
        (state.uri.toString() == AppRoutes.login ||
            state.uri.toString() == AppRoutes.register)) {
      return AppRoutes.home;
    }
    return null;
  }, */
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppView(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.feed,
              builder: (context, state) => const FeedPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => CalendarPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              builder: (context, state) => FavoritesPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.mainSearch,
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: MainSearchOverlay(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Change the opacity of the screen using a Curve based on the the animation's
            // value
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterPage(),
    ),
    GoRoute(
      path: '${AppRoutes.showOverview}/:showId',
      pageBuilder: (context, state) {
        final showId = state.pathParameters['showId'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: ShowOverviewPage(showId: showId!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Change the opacity of the screen using a Curve based on the the animation's
            // value
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.attendeeOverview}/:attendeeId',
      pageBuilder: (context, state) {
        final attendeeId = state.pathParameters['attendeeId'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: AttendeeOverviewPage(attendeeId: attendeeId!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Change the opacity of the screen using a Curve based on the the animation's
            // value
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.seasonOverview}/:seasonId',
      pageBuilder: (context, state) {
        final seasonId = state.pathParameters['seasonId'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: SeasonOverviewPage(seasonId: seasonId!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Change the opacity of the screen using a Curve based on the the animation's
            // value
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.showEventDetail}/:showEventId',
      pageBuilder: (context, state) {
        final showEventId = state.pathParameters['showEventId']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ShowEventBingoPage(showEventId: showEventId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.creatorDetail,
      pageBuilder: (context, state) {
        final event = state.extra as ResolvedCalendarEvent;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CreatorDetailPage(event: event),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.creatorEventDetail,
      pageBuilder: (context, state) {
        final event = state.extra as ResolvedCalendarEvent;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CreatorEventDetailPage(event: event),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.trashEventDetail,
      pageBuilder: (context, state) {
        final event = state.extra as ResolvedCalendarEvent;
        return CustomTransitionPage(
          key: state.pageKey,
          child: TrashEventDetailPage(event: event),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOutCirc).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
        path: AppRoutes.user,
        builder: (context, state) => UserPage(),
        routes: [
          GoRoute(
            path: AppRoutes.contentManagement,
            redirect: (context, state) {
              if (_currentUserIsEditor()) return null;
              return AppRoutes.user;
            },
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: ContentManagementPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Change the opacity of the screen using a Curve based on the the animation's
                  // value
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOutCirc)
                        .animate(animation),
                    child: child,
                  );
                },
              );
            },
          ),
        ]),
  ],
);
