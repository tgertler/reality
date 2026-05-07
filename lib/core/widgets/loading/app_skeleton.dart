import 'package:flutter/material.dart';

class AppSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF232323);
    const highlightColor = Color(0xFF353535);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle ? null : widget.borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius:
                  widget.shape == BoxShape.circle ? null : widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(-1.6 + (value * 3.2), -0.2),
                end: Alignment(1.6 + (value * 3.2), 0.2),
                colors: const [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: const [0.15, 0.5, 0.85],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppSkeletonLines extends StatelessWidget {
  final int lines;
  final double height;
  final double spacing;
  final List<double>? widths;

  const AppSkeletonLines({
    super.key,
    this.lines = 3,
    this.height = 12,
    this.spacing = 8,
    this.widths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final widthFactor = widths != null && index < widths!.length
            ? widths![index]
            : (index == lines - 1 ? 0.62 : 1.0);
        return FractionallySizedBox(
          widthFactor: widthFactor,
          child: Padding(
            padding: EdgeInsets.only(bottom: index == lines - 1 ? 0 : spacing),
            child: AppSkeletonBox(height: height),
          ),
        );
      }),
    );
  }
}

class AppSkeletonCircle extends StatelessWidget {
  final double size;

  const AppSkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBox(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }
}