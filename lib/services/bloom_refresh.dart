import 'package:flutter/foundation.dart';

/// Lightweight bump counter so the dashboard (and others) can reload
/// after local data changes — no heavy state-management framework.
class BloomRefresh {
  static final ValueNotifier<int> version = ValueNotifier(0);

  static void notify() {
    version.value = version.value + 1;
  }
}
