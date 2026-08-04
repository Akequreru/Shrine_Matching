import 'package:flutter/foundation.dart';

class RootTabSelectionRequest {
  const RootTabSelectionRequest({required this.index, required this.requestId});

  final int index;
  final int requestId;
}

class RootTabSelection {
  RootTabSelection._();

  static const int home = 0;
  static const int map = 1;
  static const int bookmark = 2;
  static const int profile = 3;

  static final ValueNotifier<RootTabSelectionRequest?> request =
      ValueNotifier<RootTabSelectionRequest?>(null);

  static int _requestCounter = 0;

  static void select(int index) {
    _requestCounter += 1;
    request.value = RootTabSelectionRequest(
      index: index,
      requestId: _requestCounter,
    );
  }
}
