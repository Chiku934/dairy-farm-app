import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility to debounce high-frequency operations such as search keystrokes,
/// slider drags, or rapid filter taps to prevent UI jank and duplicate API requests.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 350)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}
