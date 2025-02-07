/*

AUTH GATE - This will contonously listen fo auth state changes.

unauthenticated -> Login Page
authenticated -> Home Page

*/

import 'package:flutter/material.dart';
import 'package:frontend/features/user_management/pages/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;

          if (session == null) {
            return LoginPage();
          } else {
            // Navigiere zur Home Page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/home');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        });
  }
}
