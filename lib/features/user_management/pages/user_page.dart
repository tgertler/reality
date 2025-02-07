import 'package:flutter/material.dart';
import 'package:frontend/features/user_management/auth_service.dart';
import 'package:go_router/go_router.dart';

class UserPage extends StatelessWidget {
const UserPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){

    final authService = AuthService();

    void logout() async {
      await authService.signOut();
      GoRouter.of(context).go('/login');
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('User Page'),
        actions: <Widget>[
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(),
    );
  }
}