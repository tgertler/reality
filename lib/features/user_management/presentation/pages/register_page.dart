import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCaptchaVerified = false;

  void _onCaptchaVerified(String token) {
    setState(() {
      _isCaptchaVerified = true;
    });
  }

  void _onCaptchaExpired() {
    setState(() {
      _isCaptchaVerified = false;
    });
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isCaptchaVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte vervollständigen Sie das Captcha'),
        ),
      );
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      // Versuche, den Benutzer zu registrieren
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // Überprüfe, ob der Benutzer erfolgreich registriert wurde
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrierung erfolgreich! Bitte bestätigen Sie Ihre E-Mail-Adresse, bevor Sie sich anmelden.',
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // Leere die Eingabefelder nach erfolgreicher Registrierung
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    } on AuthException catch (e) {
      // Behandle spezifische Authentifizierungsfehler
      if (e.message.contains('email_exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Diese E-Mail-Adresse ist bereits registriert. Bitte melden Sie sich an.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.message}'),
          ),
        );
      }
    } catch (e) {
      // Behandle allgemeine Fehler
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  const Text(
                    'Registriere dich hier!',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    color: const Color.fromARGB(255, 248, 144, 231),
                    width: 280,
                    height: 2,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihr Passwort ein';
                      }
                      if (value.length < 6) {
                        return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort bestätigen',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte bestätigen Sie Ihr Passwort';
                      }
                      if (value != _passwordController.text) {
                        return 'Die Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      await GRecaptchaV3.execute(
                              '6LfVvfIqAAAAANFTnYwjA81Wlj_yrCbTUWxQISWX')
                          .then((token) {
                        if (token != null) {
                          _onCaptchaVerified(token);
                          signUp();
                        } else {
                          _onCaptchaExpired();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Captcha verification failed'),
                            ),
                          );
                        }
                      }).catchError((error) {
                        _onCaptchaExpired();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Captcha verification failed'),
                          ),
                        );
                      });
                    },
                    child: const Text(
                      'Registrieren',
                      style: TextStyle(color: Colors.white),
                    ),
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
