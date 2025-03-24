import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../favorites_management/presentation/providers/favorites_provider.dart';
import '../../../../user_management/presentation/providers/user_provider.dart';

class AttendeeOverviewTitleWidget extends ConsumerStatefulWidget {
  final String attendeeId;
  final String name;

  const AttendeeOverviewTitleWidget({super.key, required this.attendeeId, required this.name});

  @override
  _ShowOverviewTitleWidgetState createState() => _ShowOverviewTitleWidgetState();
}

class _ShowOverviewTitleWidgetState extends ConsumerState<AttendeeOverviewTitleWidget> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userState = ref.read(userNotifierProvider);
    if (userState.user == null) {
      // Handle user not authenticated
      return;
    }

    final userId = userState.user!.id;
    final isFavoriteShow = ref.read(isFavoriteAttendeeProvider);
    final isFavorite = await isFavoriteShow(userId, widget.attendeeId);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    final userState = ref.read(userNotifierProvider);
    if (userState.user == null) {
      // Handle user not authenticated
      return;
    }

    final userId = userState.user!.id;
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);

    if (_isFavorite) {
      await favoritesNotifier.removeAttendeeFromFavorites(userId, widget.attendeeId);
    } else {
      await favoritesNotifier.addAttendeeToFavorites(userId, widget.attendeeId);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          color: const Color.fromARGB(255, 213, 245, 245),
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: const Color.fromARGB(255, 248, 144, 231),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.black),
                    onPressed: () {
                      // Share logic here
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Text(
            widget.name,
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}