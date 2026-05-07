import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/user_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showEmailForm = false;

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

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(userNotifierProvider.notifier).signUpUser(
        _emailController.text,
        _passwordController.text,
        displayName: _nameController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registrierung erfolgreich! Bitte bestätige deine E-Mail-Adresse.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showEmailForm = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei Registrierung: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                'REGISTRIEREN',
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
                'Erstelle ein Konto um deine Shows zu verwalten.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 48),

              // Apple Sign In Button
              _AppleSignInButton(
                label: 'Mit Apple registrieren',
                onPressed: isLoading ? null : _signInWithApple,
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'oder',
                      style: GoogleFonts.dmSans(
                          color: Colors.white38, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white12)),
                ],
              ),

              const SizedBox(height: 20),

              if (!_showEmailForm)
                GestureDetector(
                  onTap: () => setState(() => _showEmailForm = true),
                  child: Center(
                    child: Text(
                      'Mit E-Mail registrieren',
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ),
                ),

              if (_showEmailForm) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.white54),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name eingeben';
                          }
                          if (v.trim().length < 2) {
                            return 'Mindestens 2 Zeichen';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Passwort eingeben';
                          if (v.length < 6) {
                            return 'Mindestens 6 Zeichen';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Passwort bestätigen',
                          labelStyle: TextStyle(color: Colors.white54),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Passwort bestätigen';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwörter stimmen nicht überein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _signUpWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pop,
                            foregroundColor: const Color(0xFF1E1E1E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            'REGISTRIEREN',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _AppleSignInButton({required this.onPressed, required this.label});

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
              label,
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
