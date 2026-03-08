import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncompleteNotifier<T> extends AsyncNotifier<T> {
  final Completer<T> _completer = Completer();

  @override
  build() => _completer.future;

  void init(T newState) {
    if (!_completer.isCompleted) {
      _completer.complete(newState);
    } else {
      // Allow subsequent updates after initial completion
      state = AsyncValue.data(newState);
    }
  }
}
