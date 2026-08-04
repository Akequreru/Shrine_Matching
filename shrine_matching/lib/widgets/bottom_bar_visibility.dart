import 'package:flutter/foundation.dart';

class RootBottomBarVisibility {
  RootBottomBarVisibility._();

  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(true);

  static void show() {
    if (!isVisible.value) {
      isVisible.value = true;
    }
  }

  static void hide() {
    if (isVisible.value) {
      isVisible.value = false;
    }
  }
}
