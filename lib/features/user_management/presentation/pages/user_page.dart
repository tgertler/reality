import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/notifications/push_notification_service.dart';
import 'package:frontend/core/notifications/push_preferences.dart';
import 'package:frontend/core/providers/push_notification_preferences_provider.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/core/widgets/not_logged_in_widget.dart';
import 'package:frontend/features/premium_management/presentation/providers/premium_waitlist_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/user_provider.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(userNotifierProvider.notifier).loadUserData();
    });
  }

  Future<void> _logout() async {
    try {
      await ref.read(userNotifierProvider.notifier).signOutUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erfolgreich abgemeldet!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        GoRouter.of(context).go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abmelden: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editProfileName(String currentName) async {
    final controller = TextEditingController(text: currentName);

    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Profilname ändern',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Dein Name',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (nextName == null || nextName.isEmpty) return;

    try {
      await ref.read(userNotifierProvider.notifier).updateProfileName(nextName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilname aktualisiert')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Account löschen?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Dein Account wird dauerhaft gelöscht. Dieser Schritt kann nicht rückgängig gemacht werden.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Endgültig löschen',
                style: TextStyle(color: Colors.redAccent.shade100),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(userNotifierProvider.notifier).deleteCurrentUserAccount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dein Account wurde geloescht.'),
          backgroundColor: Colors.green,
        ),
      );
      GoRouter.of(context).go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Loeschen des Accounts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        elevation: 0,
        actions: [
          if (userState.user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
              tooltip: 'Abmelden',
              onPressed: _logout,
            ),
        ],
      ),
      body: userState.isLoading
          ? const _UserPageSkeleton()
          : userState.user == null
              ? Center(child: NotLoggedInWidget())
              : _LoggedInBody(
                  email: userState.user!.email,
                  profileName: userState.profile?.displayName,
                  isProfileLoading: userState.isProfileLoading,
                  onLogout: _logout,
                  onEditProfileName: () => _editProfileName(
                    userState.profile?.displayName ??
                        userState.user!.email.split('@').first,
                  ),
                  onDeleteAccount: _deleteAccount,
                  onManageShows: () => GoRouter.of(context)
                      .go('${AppRoutes.user}${AppRoutes.contentManagement}'),
                ),
    );
  }
}

class _UserPageSkeleton extends StatelessWidget {
  const _UserPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Center(child: AppSkeletonCircle(size: 82)),
            SizedBox(height: 18),
            Center(child: AppSkeletonBox(width: 160, height: 20)),
            SizedBox(height: 10),
            Center(child: AppSkeletonBox(width: 220, height: 14)),
            SizedBox(height: 32),
            AppSkeletonBox(
                width: double.infinity,
                height: 112,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            SizedBox(height: 16),
            AppSkeletonBox(
                width: double.infinity,
                height: 56,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            SizedBox(height: 12),
            AppSkeletonBox(
                width: double.infinity,
                height: 56,
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ],
        ),
      ),
    );
  }
}

// ─── Logged-in body ────────────────────────────────────────────────────────────

class _LoggedInBody extends ConsumerWidget {
  final String email;
  final String? profileName;
  final bool isProfileLoading;
  final VoidCallback onLogout;
  final VoidCallback onEditProfileName;
  final VoidCallback onDeleteAccount;
  final VoidCallback onManageShows;

  const _LoggedInBody({
    required this.email,
    required this.profileName,
    required this.isProfileLoading,
    required this.onLogout,
    required this.onEditProfileName,
    required this.onDeleteAccount,
    required this.onManageShows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final metadata = supabaseUser?.appMetadata ?? const <String, dynamic>{};
    final role = metadata['role']?.toString().toLowerCase();
    final rolesRaw = metadata['roles'];
    final roles = rolesRaw is List
        ? rolesRaw.map((e) => e.toString().toLowerCase()).toList()
        : const <String>[];
    final isEditor = role == 'editor' || roles.contains('editor');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserHeaderSection(
            email: email,
            displayName: profileName,
            isProfileLoading: isProfileLoading,
            onEditProfileName: onEditProfileName,
          ),
          const SizedBox(height: 32),
          const _PushSettingsSection(),
          const SizedBox(height: 32),
          _PremiumSection(userId: supabaseUser?.id ?? ''),
          const SizedBox(height: 32),
          _ActionSection(
            onManageShows: onManageShows,
            onLogout: onLogout,
            onEditProfileName: onEditProfileName,
            onDeleteAccount: onDeleteAccount,
            showManageShows: isEditor,
          ),
        ],
      ),
    );
  }
}

// ─── Header / Identity ────────────────────────────────────────────────────────

class _UserHeaderSection extends StatelessWidget {
  final String email;
  final String? displayName;
  final bool isProfileLoading;
  final VoidCallback onEditProfileName;

  const _UserHeaderSection({
    required this.email,
    required this.displayName,
    required this.isProfileLoading,
    required this.onEditProfileName,
  });

  // Derive username: part before @ , capitalize first letter
  String get _fallbackUsername {
    final raw = email.split('@').first.replaceAll(RegExp(r'[._\-+]'), ' ');
    if (raw.isEmpty) return 'Nutzer';
    return raw
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ')
        .trim();
  }

  String get _username {
    final value = displayName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return _fallbackUsername;
  }

  // Avatar initials are derived from the chosen profile name.
  String get _avatarInitials {
    final parts = _username
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final token = parts.first;
      return token.length >= 2
          ? token.substring(0, 2).toUpperCase()
          : token.substring(0, 1).toUpperCase();
    }

    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  // Deterministic accent color based on selected profile name.
  Color get _avatarColor {
    const palette = [
      AppColors.pop,
      Color.fromARGB(207, 248, 144, 255),
      Color.fromARGB(178, 248, 144, 255),
      Color.fromARGB(130, 248, 144, 255),
      Color.fromARGB(87, 248, 144, 255),
      Color.fromARGB(50, 248, 144, 255),
    ];
    return palette[_username.hashCode.abs() % palette.length];
  }

  // Parse Supabase createdAt (ISO 8601)
  String _formattedJoinDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    const months = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${dt.day}. ${months[dt.month]} ${dt.year}';
  }

  int _daysSinceJoin(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 0;
    return DateTime.now().difference(dt).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final createdAt = supabaseUser?.createdAt;
    final joinDate = _formattedJoinDate(createdAt);
    final days = _daysSinceJoin(createdAt);

    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + status row ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Auto-Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _avatarInitials,
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E1E1E),
                      height: 1.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Login status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00B894).withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00B894),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Eingeloggt',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF00B894),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Streak / gamification badge
                  if (days > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: AppColors.pop,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔥',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            days == 1 ? '1 Tag dabei' : '$days Tage dabei',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF1E1E1E),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Username ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _username,
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
              ),
              GestureDetector(
                onTap: isProfileLoading ? null : onEditProfileName,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: const Color(0xFF252525),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color:
                            isProfileLoading ? Colors.white24 : Colors.white60,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isProfileLoading ? 'Speichern...' : 'Name',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: isProfileLoading
                              ? Colors.white24
                              : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Email / Handle ───────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.alternate_email,
                  size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                email,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
            ],
          ),

          // ── Mitglied seit ───────────────────────────────────────────────
          if (joinDate.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white12,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Colors.white24),
                const SizedBox(width: 8),
                Text(
                  'Mitglied seit $joinDate',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 13, color: Colors.white24),
                const SizedBox(width: 8),
                Text(
                  'Profil-Fortschritt: ${displayName?.trim().isNotEmpty == true ? '100%' : '70%'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _PushSettingsSection extends ConsumerWidget {
  const _PushSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pushNotificationPreferencesProvider);

    Future<void> setEnabled(bool value) async {
      try {
        await ref
            .read(pushNotificationPreferencesProvider.notifier)
            .setEnabled(value);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Push-Benachrichtigungen aktiviert'
                  : 'Push-Benachrichtigungen pausiert',
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }

    Future<void> toggleNotificationType(
      PushNotificationType type,
      bool value,
    ) async {
      try {
        await ref
            .read(pushNotificationPreferencesProvider.notifier)
            .toggleNotificationType(type);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }

    final activeCount = settings.notificationTypes.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BENACHRICHTIGUNGEN',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            color: const Color(0xFF1A1A1A),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                collapsedIconColor: Colors.white54,
                iconColor: AppColors.pop,
                title: Text(
                  'Push-Einstellungen',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  settings.enabled
                      ? '$activeCount Optionen aktiv'
                      : 'Benachrichtigungen pausiert',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Lege fest, welche Arten von Benachrichtigungen du erhalten möchtest.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                  _PushToggleTile(
                    title: 'Push-Benachrichtigungen',
                    subtitle:
                        'Aktiviert oder pausiert alle Pushes auf diesem Gerät.',
                    value: settings.enabled,
                    onChanged: setEnabled,
                  ),
                  if (settings.enabled) ...[
                    const SizedBox(height: 8),
                    for (final type in PushNotificationType.values) ...[
                      _PushToggleTile(
                        title: type.label,
                        subtitle: type.subtitle,
                        value: settings.isNotificationTypeEnabled(type),
                        onChanged: (value) =>
                            toggleNotificationType(type, value),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  _ActionTile(
                    icon: Icons.settings_outlined,
                    label: 'System-Benachrichtigungen öffnen',
                    onTap: () => PushNotificationService.instance
                        .openSystemNotificationSettings(),
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

class _PushToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PushToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.pop,
          ),
        ],
      ),
    );
  }
}

// ─── Premium Section ──────────────────────────────────────────────────────────

class _PremiumSection extends ConsumerWidget {
  final String userId;
  const _PremiumSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitlistState = ref.watch(premiumWaitlistNotifierProvider);

    if (userId.isNotEmpty && !waitlistState.hasChecked && !waitlistState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(premiumWaitlistNotifierProvider.notifier).checkStatus(userId);
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.rotate(
        angle: -0.012,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 3),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black, offset: Offset(6, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header badge ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                color: const Color(0xFFFFE600),
                child: Text(
                  'PREMIUM KOMMT BALD',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              // ── Body ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erhalte noch tiefere Einblicke in dein Profil!',
                      style: GoogleFonts.dmSans(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (userId.isEmpty)
                      Text(
                        'Melde dich an, um dich für Premium vorzumerken.',
                        style: GoogleFonts.dmSans(
                            color: Colors.black45, fontSize: 12),
                      )
                    else if (waitlistState.isLoading && !waitlistState.hasChecked)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    else if (waitlistState.isOnWaitlist)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 11, horizontal: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE600),
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.black, width: 2),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black, offset: Offset(3, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.black, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Du bist vorgemerkt',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: waitlistState.isLoading
                            ? null
                            : () => ref
                                .read(premiumWaitlistNotifierProvider.notifier)
                                .joinWaitlist(userId),
                        child: Transform.rotate(
                          angle: 0.01,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 14),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.black, width: 2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Color(0xFFFFE600),
                                    offset: Offset(4, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (waitlistState.isLoading)
                                  const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFFE600)),
                                  )
                                else
                                  const Icon(Icons.star_border_rounded,
                                      size: 16, color: Color(0xFFFFE600)),
                                const SizedBox(width: 8),
                                Text(
                                  waitlistState.isLoading
                                      ? 'Wird eingetragen…'
                                      : 'FÜR PREMIUM VORMERKEN',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFFFFE600),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
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

class _ActionSection extends StatelessWidget {
  final VoidCallback onManageShows;
  final VoidCallback onLogout;
  final VoidCallback onEditProfileName;
  final VoidCallback onDeleteAccount;
  final bool showManageShows;

  const _ActionSection({
    required this.onManageShows,
    required this.onLogout,
    required this.onEditProfileName,
    required this.onDeleteAccount,
    required this.showManageShows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFIL',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (showManageShows) ...[
            _ActionTile(
              icon: Icons.tv_outlined,
              label: 'Shows pflegen',
              onTap: onManageShows,
            ),
            const SizedBox(height: 8),
          ],
          _ActionTile(
            icon: Icons.edit,
            label: 'Profilname ändern',
            onTap: onEditProfileName,
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.logout,
            label: 'Abmelden',
            accent: Colors.redAccent.shade200,
            onTap: onLogout,
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.delete_forever_outlined,
            label: 'Account loeschen',
            accent: Colors.redAccent,
            onTap: onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: const Color(0xFF1A1A1A),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white12, size: 18),
          ],
        ),
      ),
    );
  }
}
