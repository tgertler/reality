import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:intl/intl.dart';

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

  void login() async {
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

    final userNotifier = ref.read(userNotifierProvider.notifier);

    try {
      await userNotifier.signInUser(email, password);
      if (ref.read(userNotifierProvider).user != null) {
        // Zeige eine positive Snackbar bei erfolgreichem Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erfolgreich eingeloggt!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigiere zurück zur vorherigen Seite
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.toString()) {
          case 'Exception: invalid_credentials':
            errorMessage = 'Ungültige E-Mail-Adresse oder Passwort';
            break;

          case 'Exception: email_not_confirmed':
            errorMessage = 'Die E-Mail-Adresse wurde noch nicht bestätigt';
            break;
          default:
            errorMessage = 'Ein unbekannter Fehler ist aufgetreten';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
                    'Melde dich hier an!',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    color: const Color.fromARGB(255, 248, 144, 231),
                    width: 210,
                    height: 2,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-Mail',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    style: TextStyle(color: Colors.white),
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
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihr Passwort ein';
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
                          login();
                        } else {
                          _onCaptchaExpired();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Captcha-Verifizierung fehlgeschlagen'),
                            ),
                          );
                        }
                      }).catchError((error) {
                        _onCaptchaExpired();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Captcha-Verifizierung fehlgeschlagen'),
                          ),
                        );
                      });
                    },
                    child: const Text('Einloggen',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      context.push(AppRoutes.register);
                    },
                    child: const Text('Registiere dich hier',
                        style: TextStyle(
                            color: Color.fromARGB(255, 165, 165, 165))),
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
