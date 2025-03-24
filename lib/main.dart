import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/logger.dart';
import 'core/utils/router.dart';
import 'core/config/supabase_config.dart'; // Importiere die Konfigurationsdatei

void main() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  bool ready = await GRecaptchaV3.ready(
      "6LfVvfIqAAAAANFTnYwjA81Wlj_yrCbTUWxQISWX"); //--2
  GRecaptchaV3.hideBadge();
  print("Is Recaptcha ready? $ready");

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
        fontFamily: GoogleFonts.dmSans().fontFamily,
      ),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
