import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlexibleTitleTextPart {
  final String text;
  final Color color;
  final bool isBold;

  FlexibleTitleTextPart({
    required this.text,
    required this.color,
    this.isBold = false,
  });
}

class FlexibleTitleWidget extends StatelessWidget {
  final List<FlexibleTitleTextPart> textParts;

  const FlexibleTitleWidget({super.key, required this.textParts});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: double.infinity,
      color: const Color.fromARGB(255, 248, 144, 231),
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: RichText(
          text: TextSpan(
            children: textParts.map((part) {
              return TextSpan(
                text: part.text,
                style: TextStyle(
                  color: part.color,
                  fontSize: 30,
                  fontWeight: part.isBold ? FontWeight.w900 : FontWeight.normal,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
