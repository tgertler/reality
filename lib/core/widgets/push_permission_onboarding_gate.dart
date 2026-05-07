import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/notifications/push_notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/router.dart';

class PushPermissionOnboardingGate extends StatefulWidget {
  final Widget child;
  final Future<bool> Function()? shouldShowPrompt;
  final Future<void> Function()? markPromptSeen;
  final Future<AuthorizationStatus> Function()? requestPermission;
  final Future<void> Function()? openSettings;

  const PushPermissionOnboardingGate({
    super.key,
    required this.child,
    this.shouldShowPrompt,
    this.markPromptSeen,
    this.requestPermission,
    this.openSettings,
  });

  @override
  State<PushPermissionOnboardingGate> createState() =>
      _PushPermissionOnboardingGateState();
}

class _PushPermissionOnboardingGateState
    extends State<PushPermissionOnboardingGate> {
  bool _hasCheckedPrompt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasCheckedPrompt) {
      return;
    }
    _hasCheckedPrompt = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPushPrompt();
    });
  }

  Future<void> _maybeShowPushPrompt() async {
    final service = PushNotificationService.instance;
    final shouldShow = await (widget.shouldShowPrompt != null
        ? widget.shouldShowPrompt!()
        : service.shouldShowPermissionOnboarding());

    if (!mounted || !shouldShow) {
      return;
    }

    if (appNavigatorKey.currentContext == null) {
      return;
    }

    final action = await showModalBottomSheet<_PushPromptAction>(
      context: appNavigatorKey.currentContext!,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Benachrichtigungen aktivieren',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erhalte rechtzeitig Erinnerungen vor Premieren und wichtigen Show-Events.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.pop,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tipp: Wähle im iPhone-Dialog „Erlauben“, damit Hinweise sichtbar als Banner erscheinen.',
                          style: GoogleFonts.dmSans(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_PushPromptAction.enable),
                    child: const Text('Aktivieren'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_PushPromptAction.later),
                    child: const Text('Später'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await (widget.markPromptSeen != null
        ? widget.markPromptSeen!()
        : service.markPermissionPromptSeen());

    if (!mounted || action != _PushPromptAction.enable) {
      return;
    }

    final status = await (widget.requestPermission != null
        ? widget.requestPermission!()
        : service.requestUserVisiblePermission());
    if (!mounted) {
      return;
    }

    if (status == AuthorizationStatus.denied ||
        status == AuthorizationStatus.provisional) {
      if (appNavigatorKey.currentContext == null) {
        return;
      }

      final openSettings = await showDialog<bool>(
        context: appNavigatorKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Mitteilungen anpassen',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Falls Hinweise weiter diskret erscheinen, kannst du in den iPhone-Einstellungen Banner aktivieren.',
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Später'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Einstellungen öffnen'),
              ),
            ],
          );
        },
      );

      if (openSettings == true) {
        await (widget.openSettings != null
            ? widget.openSettings!()
            : service.openSystemNotificationSettings());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

enum _PushPromptAction {
  later,
  enable,
}
