import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotLoggedInWidget extends StatelessWidget {
  const NotLoggedInWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cancel,
          size: 150,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        const Text(
          'Du bist nicht eingeloggt.',
          style: TextStyle(
              fontSize: 15, color: Color.fromARGB(255, 255, 255, 255)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            GoRouter.of(context).push('/login');
          },
          child: const Text(
            'Zum Login',
            style: TextStyle(color: Color.fromARGB(255, 255, 221, 249)),
          ),
        ),
      ],
    );
  }
}
