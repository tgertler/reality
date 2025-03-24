import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/not_logged_in_widget.dart';
import 'package:frontend/core/widgets/top_bar_nosearch_widget.dart';
import 'package:frontend/core/widgets/top_bar_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final userNotifier = ref.read(userNotifierProvider.notifier);

    void logout() async {
      try {
        await userNotifier.signOutUser();

        // Zeige eine positive Snackbar bei erfolgreichem Logout
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erfolgreich abgemeldet!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Navigiere zurück zur Startseite
        GoRouter.of(context).go('/home');
      } catch (e) {
        // Zeige eine Fehlermeldung, falls der Logout fehlschlägt
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fehler beim Abmelden: ${e.toString()}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            userState.user == null ? Color(0xFF121212) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: userState.user == null ? Colors.white : Color(0xFF121212)),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          if (userState.user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Color(0xFF121212)),
              ),
            ),
        ],
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userState.user == null
              ? Center(
                  child: NotLoggedInWidget(),
                )
              : Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        Positioned(
                          bottom: 20,
                          left: MediaQuery.of(context).size.width / 2 - 50,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 204, 201, 201),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: const Color(0xFF121212),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                '${userState.user?.email}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    GoRouter.of(context).go('/edit-profile');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    textStyle: const TextStyle(fontSize: 16),
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                  child: const Text('Profil bearbeiten',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 20),
                                OutlinedButton(
                                  onPressed: () {
                                    GoRouter.of(context).go(
                                        '${AppRoutes.user}${AppRoutes.contentManagement}');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    textStyle: const TextStyle(fontSize: 16),
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                  child: const Text('Shows pflegen',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
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
