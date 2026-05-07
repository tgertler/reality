import 'package:flutter/material.dart';

class LiveRecordingDot extends StatefulWidget {
  const LiveRecordingDot({super.key});

  @override
  State<LiveRecordingDot> createState() => _LiveRecordingDotState();
}

class _LiveRecordingDotState extends State<LiveRecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);

    // Outer pulse grows from 1.0 → 2.0
    _scale = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Fades out from 0.6 → 0.0
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withOpacity(_opacity.value),
                  ),
                ),
              );
            },
          ),

          // Inner solid dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 243, 80, 255),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}