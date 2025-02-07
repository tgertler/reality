import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/bottom_bar_widget.dart';
import 'package:frontend/features/calendar_management/presentation/pages/calendar_page.dart';
import 'package:frontend/features/favorites_management/favorites_page.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/pages/search_page.dart';
import 'package:frontend/features/user_management/pages/login_page.dart';
import 'package:frontend/features/user_management/pages/register_page.dart';
import 'package:frontend/features/user_management/pages/user_page.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/calendar_management/presentation/widgets/filter_overlay_widget.dart';
import '../../features/show_management/show_discovery/presentation/pages/show_overview_page.dart';
import '../pages/home_page.dart';

final _routerKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String calendar = '/calendar';
  static const String showOverview = '/show_overview';
  static const String mainSearch = '/main_search';
  static const String calendarFilter = '/filter';
  static const String login = '/login';
  static const String register = '/register';
  static const String user = '/user';
  static const String favorites = '/favorites';
}

final router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: AppRoutes.home,
  redirect: (context, state) {
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
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppView(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomePage(),
              routes: [
                GoRoute(
                  path: '${AppRoutes.showOverview}/:showId',
                  pageBuilder: (context, state) {
                    final showId = state.pathParameters['showId'];
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: ShowOverviewPage(showId: showId!),
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
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => CalendarPage(),
              routes: [
                GoRoute(
                  path: '${AppRoutes.showOverview}/:showId',
                  pageBuilder: (context, state) {
                    final showId = state.pathParameters['showId'];
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: ShowOverviewPage(showId: showId!),
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
              ],
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.user,
              builder: (context, state) => UserPage(),
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
      routes: [
        GoRoute(
          path: '${AppRoutes.showOverview}/:showId',
          pageBuilder: (context, state) {
            final showId = state.pathParameters['showId'];
            return CustomTransitionPage(
              key: state.pageKey,
              child: ShowOverviewPage(showId: showId!),
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
      ],
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterPage(),
    ),
  ],
);
