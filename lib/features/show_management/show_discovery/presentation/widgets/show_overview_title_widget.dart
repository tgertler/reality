import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowTitleWidget extends StatelessWidget {
  final String title;

  const ShowTitleWidget({Key? key, required this.title}) : super(key: key);

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
                  context.pop();
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: const Color.fromARGB(255, 248, 144, 231)),
                    onPressed: () {
                      // Add to favorites logic here
                    },
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
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}