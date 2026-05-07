import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _showEmailForm = false;

  Future<void> _signInWithApple() async {
    try {
      await ref.read(userNotifierProvider.notifier).signInWithApple();
      if (mounted && ref.read(userNotifierProvider).user != null) {
        context.pop();
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple Sign In fehlgeschlagen: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ein Fehler ist aufgetreten')),
        );
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(userNotifierProvider.notifier)
          .signInUser(_emailController.text, _passwordController.text);
      if (mounted && ref.read(userNotifierProvider).user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erfolgreich eingeloggt!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('invalid_credentials')
            ? 'Ungültige E-Mail-Adresse oder Passwort'
            : e.toString().contains('email_not_confirmed')
                ? 'E-Mail noch nicht bestätigt'
                : 'Ein Fehler ist aufgetreten';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'WILLKOMMEN',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 60, height: 3, color: AppColors.pop),
              const SizedBox(height: 8),
              Text(
                'Melde dich an um deine Shows zu verwalten.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 48),

              // Apple Sign In Button
              _AppleSignInButton(
                onPressed: isLoading ? null : _signInWithApple,
              ),

              const SizedBox(height: 20),

              // // Divider
              // Row(
              //   children: [
              //     Expanded(child: Divider(color: Colors.white12)),
              //     Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 12),
              //       child: Text(
              //         'oder',
              //         style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13),
              //       ),
              //     ),
              //     Expanded(child: Divider(color: Colors.white12)),
              //   ],
              // ),

              // const SizedBox(height: 20),

              // // Toggle E-Mail form
              // if (!_showEmailForm)
              //   GestureDetector(
              //     onTap: () => setState(() => _showEmailForm = true),
              //     child: Center(
              //       child: Text(
              //         'Mit E-Mail anmelden',
              //         style: GoogleFonts.dmSans(
              //           color: Colors.white38,
              //           fontSize: 14,
              //           decoration: TextDecoration.underline,
              //           decorationColor: Colors.white38,
              //         ),
              //       ),
              //     ),
              //   ),

              if (_showEmailForm) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'E-Mail',
                          labelStyle: TextStyle(color: Colors.white54),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'E-Mail eingeben';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return 'Ungültige E-Mail';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Passwort',
                          labelStyle: TextStyle(color: Colors.white54),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Passwort eingeben' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pop,
                            foregroundColor: const Color(0xFF1E1E1E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            'EINLOGGEN',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // const SizedBox(height: 32),
              // Center(
              //   child: TextButton(
              //     onPressed: () => context.push(AppRoutes.register),
              //     child: Text(
              //       'Noch kein Konto? Registrieren',
              //       style: GoogleFonts.dmSans(
              //         color: Colors.white38,
              //         fontSize: 13,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _AppleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, color: Colors.black, size: 24),
            const SizedBox(width: 10),
            Text(
              'Mit Apple anmelden',
              style: GoogleFonts.dmSans(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
