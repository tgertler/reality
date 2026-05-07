import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Wraps any feed card with a small black circular share button
/// in the top-right corner. Tapping it captures the card as a
/// PNG image and opens the system share sheet.
class FeedCardShareWrapper extends StatefulWidget {
  final Widget child;

  const FeedCardShareWrapper({super.key, required this.child});

  @override
  State<FeedCardShareWrapper> createState() => _FeedCardShareWrapperState();
}

class _FeedCardShareWrapperState extends State<FeedCardShareWrapper> {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary = _repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final dir = Directory.systemTemp;
      final file = File('${dir.path}/unscripted_feed_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Schau dir das an! 👀',
      );
    } catch (_) {
      // silently ignore share errors
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _share,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: _isSharing
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.ios_share_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
