import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainSearchOverlayProvider extends StateNotifier<bool> {
  MainSearchOverlayProvider() : super(false);

  void showOverlay() {
    state = true;
  }

  void hideOverlay() {
    state = false;
  }
}

final mainSearchOverlayProvider = StateNotifierProvider<MainSearchOverlayProvider, bool>((ref) {
  return MainSearchOverlayProvider();
});