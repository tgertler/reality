import 'package:flutter/material.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/notifications/push_notification_service.dart';
import 'package:frontend/core/widgets/push_permission_onboarding_gate.dart';
import 'core/utils/logger.dart';
import 'core/utils/router.dart';
import 'core/config/supabase_config.dart'; // Importiere die Konfigurationsdatei

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

const recaptchaKey = String.fromEnvironment('RECAPTCHA_KEY');
bool ready = await GRecaptchaV3.ready(recaptchaKey);
  GRecaptchaV3.hideBadge();
  logger.i('Is Recaptcha ready? $ready');

  await PushNotificationService.instance.initialize();

  logger.i('Application started');

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: AppColors.pop,
        colorScheme: const ColorScheme.dark(primary: AppColors.pop),
        fontFamily: GoogleFonts.dmSans().fontFamily,
      ),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return PushPermissionOnboardingGate(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
