import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/top_bar_widget.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/not_logged_in_widget.dart';
import '../providers/favorites_provider.dart';
import '../widgets/favorites_list_widget.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
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

    return Scaffold(
      appBar: TopBarWidget(),
      body: Column(
        children: [
          Container(
            height: 45,
            width: double.infinity,
            color: const Color.fromARGB(255, 248, 144, 231),
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'MEINE',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 248, 196, 239),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.oswald().fontFamily,
                      ),
                    ),
                    TextSpan(
                      text: 'FAVORITEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.oswald().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: userState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : userState.user == null
                    ? Center(
                        child: NotLoggedInWidget(),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20.0, bottom: 20.0, top: 20.0),
                        child: FavoritesListWidget(userId: userState.user!.id),
                      ),
          ),
        ],
      ),
    );
  }
}
