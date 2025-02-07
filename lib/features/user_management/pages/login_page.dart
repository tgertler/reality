import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';

import '../auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void login() async {

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await authService.signInWithEmailAndPassword(email, password);
      context.go(AppRoutes.home);
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: login,
                  child: const Text('Login'),
                ),
                TextButton(
                  onPressed: () {
                    context.push(AppRoutes.register);
                  },
                  child: const Text('Register'),
                )
              ],
            ),
          ),
        ],
      )
    );
  }
}